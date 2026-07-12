const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Inserting 4 new products into the database...');

  // 1. Ensure the 'Dry Food' category exists
  let dryFoodCategory = await prisma.category.findFirst({
    where: { Name: 'Dry Food' },
  });

  if (!dryFoodCategory) {
    dryFoodCategory = await prisma.category.create({
      data: {
        Name: 'Dry Food',
        Description: 'Dry food products for pets',
      },
    });
    console.log(`Created new Category: Dry Food (ID: ${dryFoodCategory.CategoryId})`);
  } else {
    console.log(`Found existing Category: Dry Food (ID: ${dryFoodCategory.CategoryId})`);
  }

  const categoryId = dryFoodCategory.CategoryId;

  // 2. Define the 4 new products
  const newProducts = [
    {
      ProductId: 36, // P036
      CategoryId: categoryId,
      Name: 'Me-O Tuna Adult Cat Food 1.2kg',
      Description: 'Complete and balanced dry food for adult cats, made from real fish (tuna) to support immune system, healthy eyes, skin, and coat.',
      Price: 98000,
      Stock: 80,
      ImageUrl: 'https://images.unsplash.com/photo-1569591159212-b02ea8a9f239?w=300&q=80',
    },
    {
      ProductId: 37, // P037
      CategoryId: categoryId,
      Name: 'Whiskas Gourmet Seafood Flavour 1.2kg',
      Description: 'Delicious seafood flavor dry food for adult cats aged 1+ years. Enriched with calcium, phosphorus, and vitamins to support energy, healthy joints, and shiny coat.',
      Price: 125000,
      Stock: 60,
      ImageUrl: 'https://images.unsplash.com/photo-1608454509000-195a7be8e965?w=300&q=80',
    },
    {
      ProductId: 38, // P038
      CategoryId: categoryId,
      Name: 'Royal Canin British Shorthair Adult Cat Food 2kg',
      Description: 'Tailor-made dry food for adult British Shorthair cats. Specially designed large curved kibble adapted to their broad jaw, helping support bone & joint health, muscle mass, and cardiac health.',
      Price: 395000,
      Stock: 30,
      ImageUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=300&q=80',
    },
    {
      ProductId: 39, // P039
      CategoryId: categoryId,
      Name: 'Royal Canin Hairball Care Dry Cat Food 2kg',
      Description: 'Specially formulated dry food for adult cats to reduce hairball formation. Rich in dietary fibers, including psyllium, to naturally stimulate intestinal transit and eliminate swallowed hair.',
      Price: 380000,
      Stock: 40,
      ImageUrl: 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=300&q=80',
    },
  ];

  // 3. Insert or update products
  for (const product of newProducts) {
    const existing = await prisma.product.findUnique({
      where: { ProductId: product.ProductId },
    });

    if (existing) {
      await prisma.product.update({
        where: { ProductId: product.ProductId },
        data: product,
      });
      console.log(`Updated product: ${product.Name} (ID: ${product.ProductId})`);
    } else {
      await prisma.product.create({
        data: product,
      });
      console.log(`Inserted new product: ${product.Name} (ID: ${product.ProductId})`);
    }
  }

  console.log('Success: All 4 products have been inserted/updated in the database.');
  process.exit(0);
}

main().catch((err) => {
  console.error('Error seeding new products:', err);
  process.exit(1);
});
