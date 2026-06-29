const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const productCount = await prisma.product.count();
  const categoryCount = await prisma.category.count();
  const userCount = await prisma.user.count();
  const cartItemCount = await prisma.cartItem.count();
  console.log(`--- DB STATUS ---`);
  console.log(`Users: ${userCount}`);
  console.log(`Categories: ${categoryCount}`);
  console.log(`Products: ${productCount}`);
  console.log(`Cart Items: ${cartItemCount}`);
  if (productCount === 0) {
    console.log('No products in the database. Let us seed some products based on the local data!');
  } else {
    const sample = await prisma.product.findFirst({ include: { Category: true } });
    console.log('Sample Product:', JSON.stringify(sample, null, 2));
  }
  process.exit(0);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
