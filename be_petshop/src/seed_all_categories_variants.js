const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Seeding dynamic VariantLabel, Unit and Variants for all 6 categories...');

  // Find all products
  const products = await prisma.product.findMany({
    include: { Category: true }
  });

  let updatedCount = 0;
  for (const product of products) {
    const catNameLower = (product.Category.Name || '').toLowerCase();
    const nameLower = product.Name.toLowerCase();

    let unit = 'cái';
    let variantLabel = null;
    let variants = null;

    if (catNameLower.includes('thức ăn hạt')) {
      unit = 'túi';
      variantLabel = 'Khối lượng';
      variants = [
        { name: 'Túi 500g', price: Math.round(product.Price * 0.6), stock: 45 },
        { name: 'Túi 1 Kg', price: product.Price, stock: 35 },
        { name: 'Bao 5 Kg', price: Math.round(product.Price * 4.5), stock: 20 },
        { name: 'Bao 10 Kg', price: Math.round(product.Price * 8.2), stock: 10 }
      ];
    } else if (catNameLower.includes('pate') || catNameLower.includes('súp')) {
      unit = 'lon';
      variantLabel = 'Đóng gói';
      variants = [
        { name: 'Lon lẻ 85g', price: product.Price, stock: 120 },
        { name: 'Lon to 150g', price: Math.round(product.Price * 1.6), stock: 80 },
        { name: 'Lốc 6 lon', price: Math.round(product.Price * 5.5), stock: 30 }
      ];
    } else if (catNameLower.includes('bánh thưởng')) {
      unit = 'gói';
      variantLabel = 'Hương vị';
      variants = [
        { name: 'Vị Gà nướng', price: product.Price, stock: 50 },
        { name: 'Vị Cá Hồi tươi', price: product.Price, stock: 40 },
        { name: 'Vị Bò sữa', price: Math.round(product.Price * 1.1), stock: 30 }
      ];
    } else if (catNameLower.includes('vệ sinh') || catNameLower.includes('cát')) {
      unit = 'túi';
      variantLabel = 'Thể tích';
      variants = [
        { name: 'Túi 5 Lít', price: product.Price, stock: 60 },
        { name: 'Túi to 10 Lít', price: Math.round(product.Price * 1.8), stock: 40 }
      ];
    } else if (catNameLower.includes('phụ kiện') || nameLower.includes('vòng cổ') || nameLower.includes('balo') || nameLower.includes('dây dắt')) {
      unit = 'cái';
      variantLabel = 'Kích cỡ';
      variants = [
        { name: 'Size S', price: Math.round(product.Price * 0.9), stock: 25 },
        { name: 'Size M', price: product.Price, stock: 20 },
        { name: 'Size L', price: Math.round(product.Price * 1.2), stock: 15 }
      ];
    } else if (catNameLower.includes('chăm sóc sức khỏe') || catNameLower.includes('sữa tắm') || nameLower.includes('shampoo') || nameLower.includes('thuốc')) {
      unit = 'chai';
      variantLabel = 'Dung tích';
      variants = [
        { name: 'Chai 250ml', price: product.Price, stock: 35 },
        { name: 'Chai lớn 500ml', price: Math.round(product.Price * 1.7), stock: 20 }
      ];
    } else {
      // Default / generic products that don't have variants
      unit = 'cái';
      variantLabel = null;
      variants = null;
    }

    await prisma.product.update({
      where: { ProductId: product.ProductId },
      data: {
        Unit: unit,
        VariantLabel: variantLabel,
        Variants: variants
      }
    });

    console.log(`Updated product: ${product.Name}`);
    console.log(`- Category: ${product.Category.Name}`);
    console.log(`- Unit: ${unit}`);
    console.log(`- VariantLabel: ${variantLabel}`);
    if (variants) {
      console.log(`- Variants: ${variants.map(v => `${v.name} (${v.price}đ)`).join(', ')}`);
    }
    console.log('----------------------------------------------------');
    updatedCount++;
  }

  console.log(`Successfully completed seeding for ${updatedCount} products!`);
  process.exit(0);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
