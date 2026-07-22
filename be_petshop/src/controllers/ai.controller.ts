import { AppError } from '../middleware/error.middleware';
import { AiService } from '../services/ai.service';
import { z } from 'zod';

const aiService = new AiService();

const chatSchema = z.object({
  message: z.string().min(1, 'Message is required'),
  sessionId: z.string().optional(),
});

export class AiController {
  async handleChat(req: Request) {
    try {
      const body = await req.json();
      
      // Validate request body
      const { message, sessionId } = chatSchema.parse(body);

      // Call AiService to handle the chat logic
      const response = await aiService.handleChat(message, sessionId || 'default-session');

      return Response.json(response);
    } catch (error) {
      if (error instanceof z.ZodError) {
        throw new AppError('Validation failed: ' + error.errors.map(e => e.message).join(', '), 400);
      }
      throw error;
    }
  }
}
