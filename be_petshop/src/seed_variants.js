const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Seeding weight/bag variants for food products...');

  // Find all products
  const products = await prisma.product.findMany({
    include: { Category: true }
  });

  let updatedCount = 0;
  for (const product of products) {
    const nameLower = product.Name.toLowerCase();
    const catNameLower = (product.Category.Name || '').toLowerCase();

    // If it's a food category or food product name
    if (
      catNameLower.includes('thức ăn') ||
      catNameLower.includes('dinh dưỡng') ||
      catNameLower.includes('food') ||
      nameLower.includes('hạt') ||
      nameLower.includes('thức ăn') ||
      nameLower.includes('pate') ||
      nameLower.includes('royal canin') ||
      nameLower.includes('whiskas')
    ) {
      // Setup variants: 500g, 1kg, Bao 5kg, Bao 10kg
      const variants = [
        {
          name: 'Túi 500g',
          price: Math.round(product.Price * 0.6),
          stock: 45
        },
        {
          name: 'Túi 1 Kg',
          price: product.Price, // Base price
          stock: 35
        },
        {
          name: 'Bao 5 Kg',
          price: Math.round(product.Price * 4.5),
          stock: 20
        },
        {
          name: 'Bao 10 Kg',
          price: Math.round(product.Price * 8.2),
          stock: 10
        }
      ];

      await prisma.product.update({
        where: { ProductId: product.ProductId },
        data: {
          Variants: variants
        }
      });
      console.log(`Updated variants for: ${product.Name} (Category: ${product.Category.Name})`);
      updatedCount++;
    }
  }

  console.log(`Successfully updated ${updatedCount} products with weight variants!`);
  process.exit(0);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
