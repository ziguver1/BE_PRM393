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

const products = [
  {
    Name: 'Hạt mèo Royal Canin Indoor',
    Description: 'Hạt dinh dưỡng cao cấp cho mèo trưởng thành, hỗ trợ tiêu hóa và duy trì cân nặng lý tưởng.',
    Price: 329000,
    Stock: 24,
    ImageUrl: 'https://res.cloudinary.com/dltxwrzsg/image/upload/v1783892089/4401fa02-4560-42e6-aa3f-e7bee4716160.png',
    CategoryName: 'Thức ăn hạt',
  },
  {
    Name: 'Pate mèo Fancy Feast',
    Description: 'Pate mèo thơm ngon, giàu protein và phù hợp cho mèo cần dinh dưỡng hấp thu tốt.',
    Price: 189000,
    Stock: 36,
    ImageUrl: 'https://res.cloudinary.com/dltxwrzsg/image/upload/v1783892052/f2d3978e-cf51-484b-8c5a-00537737e023.png',
    CategoryName: 'Pate & Súp',
  },
  {
    Name: 'Pate mèo Whiskas Premium',
    Description: 'Pate mèo mềm thơm, tiện lợi cho bữa ăn hàng ngày và tăng cảm giác no lâu.',
    Price: 159000,
    Stock: 30,
    ImageUrl: 'https://res.cloudinary.com/dltxwrzsg/image/upload/v1783892018/1adeb62f-fae5-4eb3-9226-235ad35da5ac.png',
    CategoryName: 'Pate & Súp',
  },
  {
    Name: 'Hạt mèo Purina One',
    Description: 'Hạt mèo cao cấp với công thức cân bằng, hỗ trợ hệ miễn dịch và da lông khỏe mạnh.',
    Price: 299000,
    Stock: 22,
    ImageUrl: 'https://res.cloudinary.com/dltxwrzsg/image/upload/v1783891999/5f9d0b2b-55aa-4f1b-96de-4cd7911ceefe.png',
    CategoryName: 'Thức ăn hạt',
  },
  {
    Name: 'Hạt chó Pedigree Adult',
    Description: 'Hạt cho chó trưởng thành, giàu dinh dưỡng và dễ tiêu hóa cho hoạt động hàng ngày.',
    Price: 279000,
    Stock: 28,
    ImageUrl: 'https://res.cloudinary.com/dltxwrzsg/image/upload/v1783891978/09f2a747-5640-474a-a8a9-cfd0c819ddd3.png',
    CategoryName: 'Thức ăn hạt',
  },
  {
    Name: 'Pate chó Cesar Gourmet',
    Description: 'Pate chó thơm ngon, giàu protein và được nhiều bé cưng yêu thích.',
    Price: 179000,
    Stock: 40,
    ImageUrl: 'https://res.cloudinary.com/dltxwrzsg/image/upload/v1783891929/7659b3e0-1b0d-4ca5-b0e4-85341750311a.png',
    CategoryName: 'Pate & Súp',
  },
  {
    Name: 'Pate chó Pro Plan Adult',
    Description: 'Pate cho chó trưởng thành, công thức thượng hạng hỗ trợ sức khỏe và năng lượng.',
    Price: 219000,
    Stock: 26,
    ImageUrl: 'https://res.cloudinary.com/dltxwrzsg/image/upload/v1783891871/134e4779-a39a-417c-9e32-08af69558804.png',
    CategoryName: 'Pate & Súp',
  },
  {
    Name: 'Hạt chó Royal Canin Puppy',
    Description: 'Hạt cho chó con, cung cấp dinh dưỡng tối ưu cho sự phát triển toàn diện.',
    Price: 349000,
    Stock: 18,
    ImageUrl: 'https://res.cloudinary.com/dltxwrzsg/image/upload/v1783891918/2bec160a-0b8c-4588-9f14-5f901928daa8.png',
    CategoryName: 'Thức ăn hạt',
  },
];

async function main() {
  console.log('Resetting category and product data...');
  await prisma.product.deleteMany();
  await prisma.category.deleteMany();

  console.log('Inserting Vietnamese categories...');
  const createdCategories = await prisma.category.createMany({
    data: categories,
  });

  const categoryRecords = await prisma.category.findMany();
  const categoryMap = new Map(categoryRecords.map((category) => [category.Name, category.CategoryId]));

  console.log('Inserting products with Cloudinary images...');
  const productData = products.map((product) => ({
    CategoryId: categoryMap.get(product.CategoryName),
    Name: product.Name,
    Description: product.Description,
    Price: product.Price,
    Stock: product.Stock,
    ImageUrl: product.ImageUrl,
  }));

  await prisma.product.createMany({
    data: productData,
  });

  console.log(`Seed completed successfully. Inserted ${createdCategories.count} categories and ${products.length} products.`);
}

main()
  .catch((error) => {
    console.error('Failed to seed categories and products:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
