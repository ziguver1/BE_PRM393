const fs = require('fs');
const path = require('path');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

// Path to pet_knowledge_data.dart
const dartFilePath = path.join(__dirname, '../../fe_pet/lib/data/pet_knowledge_data.dart');

async function main() {
  console.log('Reading dart file...');
  const content = fs.readFileSync(dartFilePath, 'utf8');

  // Regex to extract PetKnowledgeItem constructor calls
  // Match fields: id, name, brand, category, price, stock, description, imageUrl
  const itemRegex = /PetKnowledgeItem\s*\(\s*id:\s*'([^']+)'[\s\S]*?name:\s*'([^']+)'[\s\S]*?brand:\s*'([^']+)'[\s\S]*?category:\s*'([^']+)'[\s\S]*?price:\s*(\d+)[\s\S]*?stock:\s*(\d+)[\s\S]*?description:\s*'([^']+)'/g;

  let match;
  const items = [];
  while ((match = itemRegex.exec(content)) !== null) {
    items.push({
      idStr: match[1], // e.g. "P001"
      name: match[2],
      brand: match[3],
      categoryName: match[4],
      price: parseFloat(match[5]),
      stock: parseInt(match[6], 10),
      description: match[7],
    });
  }

  console.log(`Parsed ${items.length} items from Dart file.`);
  if (items.length === 0) {
    // If double quotes or other variations, let's try a fallback parser
    console.log('Trying fallback parser...');
    const blocks = content.split('PetKnowledgeItem(').slice(1);
    for (const block of blocks) {
      const getField = (field) => {
        const regex = new RegExp(`${field}:\\s*['"]([^'"]+)['"]`);
        const m = block.match(regex);
        return m ? m[1] : '';
      };
      const getIntField = (field) => {
        const regex = new RegExp(`${field}:\\s*(\\d+)`);
        const m = block.match(regex);
        return m ? parseInt(m[1], 10) : 0;
      };
      
      const idStr = getField('id');
      const name = getField('name');
      const brand = getField('brand');
      const categoryName = getField('category');
      const price = getIntField('price');
      const stock = getIntField('stock');
      const description = getField('description');
      
      if (idStr && name) {
        items.push({
          idStr,
          name,
          brand,
          categoryName: categoryName || 'Other',
          price,
          stock,
          description,
        });
      }
    }
    console.log(`Fallback parsed ${items.length} items.`);
  }

  // Clear existing items in database
  console.log('Clearing database tables...');
  await prisma.cartItem.deleteMany();
  await prisma.orderDetail.deleteMany();
  await prisma.order.deleteMany();
  await prisma.product.deleteMany();
  await prisma.category.deleteMany();

  // Extract unique categories
  const categoryNames = [...new Set(items.map(item => item.categoryName))];
  console.log('Found categories:', categoryNames);

  // Insert categories
  const categoryMap = new Map();
  for (const name of categoryNames) {
    const category = await prisma.category.create({
      data: {
        Name: name,
        Description: `${name} products for pets`,
      },
    });
    categoryMap.set(name, category.CategoryId);
  }

  // Insert products
  console.log('Inserting products...');
  for (const item of items) {
    const categoryId = categoryMap.get(item.categoryName);
    
    // Parse numeric ID (e.g. P001 -> 1)
    const productId = parseInt(item.idStr.replace(/\D/g, ''), 10);

    await prisma.product.create({
      data: {
        ProductId: productId,
        CategoryId: categoryId,
        Name: item.name,
        Description: item.description,
        Price: item.price,
        Stock: item.stock,
        ImageUrl: `https://images.unsplash.com/photo-1589924691106-07a2c75b7fd7?w=300&q=80`, // Placeholder image
      },
    });
  }

  console.log('Seeding completed successfully!');
  
  // Create a default customer user for ease of testing if none exists
  const existingUser = await prisma.user.findFirst();
  if (!existingUser) {
    const bcrypt = require('bcryptjs');
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash('password123', salt);
    await prisma.user.create({
      data: {
        FullName: 'Demo Customer',
        Email: 'customer@pawmart.com',
        PasswordHash: passwordHash,
        Phone: '0987654321',
        Role: 'CUSTOMER',
      },
    });
    console.log('Seeded a demo user: customer@pawmart.com / password123');
  }

  process.exit(0);
}

main().catch(err => {
  console.error('Error during seeding:', err);
  process.exit(1);
});
