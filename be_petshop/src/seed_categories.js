const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

const categories = [
  {
    Name: 'Thức ăn hạt',
    Description: 'Thức ăn khô, hạt dinh dưỡng cho chó mèo',
    ImageUrl: 'public/images/pets_icon.png',
  },
  {
    Name: 'Pate & Súp',
    Description: 'Thức ăn ướt, pate lon, túi nhai, súp thưởng',
    ImageUrl: 'public/images/pets_icon.png',
  },
  {
    Name: 'Bánh thưởng',
    Description: 'Xương gặm, bánh quy, snack huấn luyện',
    ImageUrl: 'public/images/pets_icon.png',
  },
  {
    Name: 'Đồ vệ sinh',
    Description: 'Cát mèo, khay vệ sinh, xịt khử mùi, tã lót',
    ImageUrl: 'public/images/pets_icon.png',
  },
  {
    Name: 'Phụ kiện',
    Description: 'Vòng cổ, dây dắt, balo vận chuyển, quần áo',
    ImageUrl: 'public/images/pets_icon.png',
  },
  {
    Name: 'Chăm sóc sức khỏe',
    Description: 'Sữa tắm, thuốc trị rận, tẩy giun, vitamin',
    ImageUrl: 'public/images/pets_icon.png',
  },
];

async function main() {
  console.log('Resetting category data...');
  await prisma.category.deleteMany();

  console.log('Inserting Vietnamese categories...');
  await prisma.category.createMany({
    data: categories,
  });

  console.log('Seed categories completed successfully.');
}

main()
  .catch((error) => {
    console.error('Failed to seed categories:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
