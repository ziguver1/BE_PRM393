const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('=== Bắt đầu nạp 7 Categories cho PawMart ===');

  const categories = [
    { Name: 'Thức ăn cho Chó', Description: 'Hạt khô, pate, thức ăn ướt dành cho chó', ImageUrl: 'https://placehold.co/400x400/FF7F50/FFF?text=Dog+Food' },
    { Name: 'Thức ăn cho Mèo', Description: 'Hạt khô, pate, súp thưởng dành cho mèo', ImageUrl: 'https://placehold.co/400x400/FF7F50/FFF?text=Cat+Food' },
    { Name: 'Bánh thưởng & Snack', Description: 'Đồ ăn vặt, xương gặm, bánh thưởng huấn luyện', ImageUrl: 'https://placehold.co/400x400/FF7F50/FFF?text=Treats' },
    { Name: 'Vệ sinh & Cát', Description: 'Cát vệ sinh mèo, khay vệ sinh, xịt khử mùi', ImageUrl: 'https://placehold.co/400x400/FF7F50/FFF?text=Hygiene' },
    { Name: 'Phụ kiện & Quần áo', Description: 'Vòng cổ, dây dắt, rọ mõm, balo, quần áo', ImageUrl: 'https://placehold.co/400x400/FF7F50/FFF?text=Accessories' },
    { Name: 'Đồ chơi', Description: 'Cần câu mèo, bóng cao su, đồ chơi thừng, bàn cào', ImageUrl: 'https://placehold.co/400x400/FF7F50/FFF?text=Toys' },
    { Name: 'Chăm sóc sức khỏe', Description: 'Sữa tắm, lược chải, tông đơ, vitamin bổ sung', ImageUrl: 'https://placehold.co/400x400/FF7F50/FFF?text=Health' },
  ];

  // Dùng vòng lặp tạo từng Category
  for (const cat of categories) {
    await prisma.category.create({
      data: cat,
    });
  }

  console.log('=== Nạp thành công trọn vẹn 7 danh mục vào DB! ===');
}

main()
  .catch((e) => {
    console.error('Lỗi trong quá trình seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });