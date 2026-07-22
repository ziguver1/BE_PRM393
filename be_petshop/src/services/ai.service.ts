import { GoogleGenerativeAI, Content } from '@google/generative-ai';
import prisma from '../lib/prisma';
import { AppError } from '../middleware/error.middleware';

// Initialize Gemini API once
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');

interface CacheEntry {
  reply: string;
  timestamp: number;
}

export class AiService {
  private static sessionMemory = new Map<string, Content[]>();
  private static responseCache = new Map<string, CacheEntry>();
  
  // Cache TTL: 5 minutes
  private static CACHE_TTL_MS = 5 * 60 * 1000;

  async handleChat(message: string, sessionId: string = 'default-session') {
    if (!process.env.GEMINI_API_KEY) {
      throw new AppError('Gemini API key is not configured', 500);
    }

    const tStart = performance.now();
    let tIntent = 0, tDb = 0, tGemini = 0;
    let cacheHit = false;
    let dbQueryMade = false;
    let productsCount = 0;
    let detectionSource = 'RULE';

    // Get conversation history (last 4 messages to save tokens and maintain user/model parity)
    let history = AiService.sessionMemory.get(sessionId) || [];
    if (history.length > 4) {
      history = history.slice(history.length - 4);
    }

    // Step 1: Intent Detection (Hybrid)
    const tIntentStart = performance.now();
    let intent = this.localDetectIntent(message);
    
    if (intent.intent === 'UNKNOWN' || intent.intent === 'UNCERTAIN') {
      detectionSource = 'GEMINI';
      intent = await this.withRetry(() => this.geminiDetectIntent(message, history), 2);
    }
    tIntent = performance.now() - tIntentStart;

    let products: any[] = [];
    let reply = "";

    // Step 2: Caching check
    const isCacheable = (intent.intent === 'GENERAL_CHAT' || intent.intent === 'PET_KNOWLEDGE');
    const cacheKey = message.trim().toLowerCase();

    if (isCacheable && AiService.responseCache.has(cacheKey)) {
      const entry = AiService.responseCache.get(cacheKey)!;
      if (Date.now() - entry.timestamp < AiService.CACHE_TTL_MS) {
        reply = entry.reply;
        cacheHit = true;
      }
    }

    if (!cacheHit) {
      // Step 3: Database Query
      const tDbStart = performance.now();
      if (intent.intent === 'PRODUCT_SEARCH' || intent.intent === 'PRODUCT_COMPARISON') {
        products = await this.fetchProducts(intent);
        dbQueryMade = true;
        productsCount = products.length;
      }
      tDb = performance.now() - tDbStart;

      // Step 4: Response Generation with Retry & Graceful Fallback
      const tGeminiStart = performance.now();
      try {
        reply = await this.withRetry(() => this.generateResponse(message, products, history), 2);
        
        // Cache result if applicable
        if (isCacheable) {
          AiService.responseCache.set(cacheKey, { reply, timestamp: Date.now() });
        }
      } catch (e) {
        console.error("Gemini API failed after retries:", e);
        // Graceful fallback
        if (dbQueryMade && productsCount > 0) {
          reply = "Hiện tại hệ thống AI đang bận, nhưng tôi đã tìm thấy một số sản phẩm phù hợp cho bạn bên dưới.";
        } else {
          reply = "The AI service is currently busy. Please try again in a few moments.";
        }
      }
      tGemini = performance.now() - tGeminiStart;
    }

    // Step 5: Save to Memory
    history.push({ role: 'user', parts: [{ text: message }] });
    history.push({ role: 'model', parts: [{ text: reply }] });
    AiService.sessionMemory.set(sessionId, history);

    const totalTime = performance.now() - tStart;
    
    // Logging Optimization Details
    console.log(`
--- AI Request Profile ---
Intent:             ${intent.intent}
Detection:          ${detectionSource}
Cache Hit:          ${cacheHit ? 'YES' : 'NO'}
Database Query:     ${dbQueryMade ? 'YES' : 'NO'}
Products Retrieved: ${productsCount}
Intent Time:        ${tIntent.toFixed(2)}ms
Prisma Time:        ${tDb.toFixed(2)}ms
Gemini API Time:    ${tGemini.toFixed(2)}ms
Total Time:         ${totalTime.toFixed(2)}ms
--------------------------
`);

    return {
      reply,
      products: products.map(p => ({
        id: p.ProductId,
        name: p.Name,
        price: p.Price,
        image: p.Images?.[0]?.ImageUrl || p.ImageUrl,
      })),
    };
  }

  private localDetectIntent(message: string): any {
    const msg = message.toLowerCase();
    
    let intentStr = 'UNCERTAIN';
    
    // 1. Detect Intent Type
    if (msg.match(/so sánh|khác nhau|nên mua loại nào/)) {
      intentStr = 'PRODUCT_COMPARISON';
    } else if (msg.match(/mua|giá|thức ăn|pate|cát|hạt|balo|sữa tắm|đồ chơi|tìm|bán|có/)) {
      intentStr = 'PRODUCT_SEARCH';
    } else if (msg.match(/tại sao|làm sao|làm thế nào|cách|ăn được không|bệnh|chăm sóc/)) {
      intentStr = 'PET_KNOWLEDGE';
    } else if (msg.match(/^chào|^hi$|^hello$|kể chuyện|thơ|bạn là ai|thời tiết/)) {
      intentStr = 'GENERAL_CHAT';
    }

    if (intentStr === 'UNCERTAIN') return { intent: 'UNCERTAIN' };

    // 2. Extract Entities
    let petType = null;
    if (msg.match(/chó|cún|dog|puppy/)) petType = 'DOG';
    else if (msg.match(/mèo|cat|kitten|mimi/)) petType = 'CAT';

    let maxPrice = null;
    const priceMatch = msg.match(/(dưới|<|rẻ hơn|tối đa) (\d+)(k| nghìn| vnd|vnđ)/);
    if (priceMatch) {
      const num = parseInt(priceMatch[2]);
      if (priceMatch[3] === 'k' || priceMatch[3] === ' nghìn') maxPrice = num * 1000;
      else maxPrice = num;
    }

    let brand = null;
    const brands = ['royal canin', 'smartheart', 'whiskas', 'ciao', 'me-o', 'pedigree', 'purina'];
    for (const b of brands) {
      if (msg.includes(b)) {
        brand = b;
        break;
      }
    }

    let keywords = null;
    const keywordMatch = msg.match(/pate|hạt|cát|balo|sữa tắm|đồ chơi/);
    if (keywordMatch) keywords = keywordMatch[0];

    return {
      intent: intentStr,
      petType,
      maxPrice,
      minPrice: null,
      brand,
      keywords
    };
  }

  private async geminiDetectIntent(message: string, history: Content[]) {
    try {
      const model = genAI.getGenerativeModel({ 
        model: 'gemini-flash-latest'
      });

      const historyContext = history.map(h => `${h.role}: ${h.parts[0]?.text}`).join('\n');
      
      const prompt = `
Extract user's intent. Return ONLY a valid JSON object without markdown formatting.
- "intent": "PRODUCT_SEARCH" | "PRODUCT_COMPARISON" | "PET_KNOWLEDGE" | "GENERAL_CHAT" | "STORE_INFORMATION" | "UNKNOWN"
- "petType": "DOG" | "CAT" | null
- "maxPrice": number | null
- "minPrice": number | null
- "brand": string | null
- "keywords": string | null

Context:
${historyContext}

Message: "${message}"
`;

      const result = await model.generateContent(prompt);
      const response = await result.response;
      return this.safeParseJson(response.text());
    } catch (e) {
      console.error("Failed to parse intent JSON from Gemini:", e);
      return { intent: 'UNKNOWN' };
    }
  }

  private safeParseJson(text: string): any {
    try {
      // Find the first { and last } to extract JSON block safely
      const start = text.indexOf('{');
      const end = text.lastIndexOf('}');
      if (start !== -1 && end !== -1) {
        const jsonStr = text.substring(start, end + 1);
        return JSON.parse(jsonStr);
      }
      return JSON.parse(text);
    } catch (e) {
      console.error("Error safe-parsing JSON:", e);
      return { intent: 'UNKNOWN' };
    }
  }

  private async fetchProducts(intent: any) {
    const { petType, maxPrice, minPrice, brand, keywords } = intent;
    
    const where: any = {};
    const andConditions: any[] = [];

    if (maxPrice || minPrice) {
      const priceCondition: any = {};
      if (minPrice) priceCondition.gte = Number(minPrice);
      if (maxPrice) priceCondition.lte = Number(maxPrice);
      andConditions.push({ Price: priceCondition });
    }

    if (petType) {
      andConditions.push({
        Category: {
          Name: {
            contains: petType === 'DOG' ? 'Chó' : (petType === 'CAT' ? 'Mèo' : petType),
            mode: 'insensitive'
          }
        }
      });
    }
    
    const searchTokens = [brand, keywords].filter(Boolean);
    if (searchTokens.length > 0) {
      const searchStr = searchTokens.join(' ');
      andConditions.push({
        OR: [
          { Name: { contains: searchStr, mode: 'insensitive' } },
          { Description: { contains: searchStr, mode: 'insensitive' } }
        ]
      });
    }

    if (andConditions.length > 0) {
      where.AND = andConditions;
    }

    try {
      // Optimizied selection: avoids unnecessary joins and fields
      const products = await prisma.product.findMany({
        where,
        take: 10,
        select: {
          ProductId: true,
          Name: true,
          Price: true,
          ImageUrl: true,
          Description: true,
          Stock: true,
          Images: {
            take: 1,
            select: { ImageUrl: true }
          },
          Category: {
            select: { Name: true }
          }
        }
      });
      return products;
    } catch (e) {
      console.error("Error fetching products:", e);
      return [];
    }
  }

  private async generateResponse(message: string, products: any[], history: Content[]): Promise<string> {
    let systemInstruction = `You are PawMart AI Assistant.
Recommend products accurately using ONLY provided context. Never invent products, prices, or stock.
If no product context is provided, answer general questions based on your knowledge.
Be polite and professional ("tôi" and "bạn" or "quý khách"). Respond in Vietnamese.`;

    const model = genAI.getGenerativeModel({ 
      model: 'gemini-flash-latest',
      systemInstruction
    });
    
    const chat = model.startChat({ history });

    let fullMessage = message;
    if (products.length > 0) {
      const productContext = products.map(p => {
        // Truncate description to save tokens
        const shortDesc = p.Description && p.Description.length > 100 
          ? p.Description.substring(0, 100) + '...' 
          : p.Description || '';
        return `- ${p.Name} (Price: ${p.Price}, Category: ${p.Category?.Name || 'Unknown'}) - ${shortDesc}`;
      }).join('\n');
      
      fullMessage += `\n\n[CONTEXT]: Available Products:\n${productContext}`;
    }

    const result = await chat.sendMessage(fullMessage);
    const response = await result.response;
    return response.text();
  }

  private async withRetry<T>(fn: () => Promise<T>, maxRetries: number): Promise<T> {
    let retries = 0;
    while (true) {
      try {
        return await fn();
      } catch (error: any) {
        if (retries >= maxRetries) {
          throw error;
        }
        
        // Don't retry on non-transient errors (like 400 Bad Request)
        if (error?.status && error.status !== 429 && (error.status < 500)) {
           throw error;
        }

        retries++;
        const backoff = retries === 1 ? 500 : 1000;
        console.warn(`Gemini API attempt ${retries} failed. Retrying in ${backoff}ms...`);
        await new Promise(resolve => setTimeout(resolve, backoff));
      }
    }
  }
}
