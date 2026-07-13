const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('=== Bắt đầu nạp dữ liệu sản phẩm (Products) ===');

  // 1. Lấy thông tin CategoryId từ DB để đảm bảo không bị lệch ID ngoại khóa
  const catCategory = await prisma.category.findFirst({
    where: { Name: 'Thức ăn cho Mèo' }
  });

  const dogCategory = await prisma.category.findFirst({
    where: { Name: 'Thức ăn cho Chó' }
  });

  if (!catCategory || !dogCategory) {
    console.error('Lỗi: Không tìm thấy danh mục "Thức ăn cho Mèo" hoặc "Thức ăn cho Chó" trong DB. Vui lòng chạy seed category trước!');
    return;
  }

  console.log(`Đã tìm thấy mã danh mục - Mèo: ${catCategory.CategoryId}, Chó: ${dogCategory.CategoryId}`);

  // 2. Định nghĩa danh sách 4 sản phẩm cho Mèo kèm 4 link ảnh đầu tiên
  const catProducts = [
    {
      CategoryId: catCategory.CategoryId,
      Name: 'Thức ăn hạt cho mèo trưởng thành Whiskas Vị cá biển',
      Description: 'Thức ăn dạng hạt thơm ngon, cung cấp đầy đủ dinh dưỡng, giúp mèo sáng mắt và mượt lông.',
      Price: 125000,
      Stock: 80,
      ImageUrl: 'https://res.cloudinary.com/dltxwrzsg/image/upload/v1783892089/4401fa02-4560-42e6-aa3f-e7bee4716160.png',
      Unit: 'túi'
    },
    {
      CategoryId: catCategory.CategoryId,
      Name: 'Pate cho mèo con Royal Canin Mother & Babycat',
      Description: 'Dạng thức ăn siêu mềm mịn, dễ tiêu hóa, hỗ trợ tối đa hệ miễn dịch cho mèo con dưới 4 tháng tuổi.',
      Price: 45000,
      Stock: 150,
      ImageUrl: 'https://res.cloudinary.com/dltxwrzsg/image/upload/v1783892052/f2d3978e-cf51-484b-8c5a-00537737e023.png',
      Unit: 'túi'
    },
    {
      CategoryId: catCategory.CategoryId,
      Name: 'Thức ăn hạt dinh dưỡng cho mèo Catsrang nhập khẩu Hàn Quốc',
      Description: 'Giúp giảm thiểu mùi hôi của phân, ngăn ngừa búi lông trong dạ dày, phù hợp cho mọi lứa tuổi.',
      Price: 95000,
      Stock: 60,
      ImageUrl: 'https://res.cloudinary.com/dltxwrzsg/image/upload/v1783892018/1adeb62f-fae5-4eb3-9226-235ad35da5ac.png',
      Unit: 'túi'
    },
    {
      CategoryId: catCategory.CategoryId,
      Name: 'Súp thưởng cho mèo Me-O Creamy Treats Vị cá hồi',
      Description: 'Thức ăn nhẹ dạng kem bổ sung vitamin sáp, kích thích vị giác giúp mèo ăn ngon miệng hơn.',
      Price: 35000,
      Stock: 200,
      ImageUrl: 'https://res.cloudinary.com/dltxwrzsg/image/upload/v1783891999/5f9d0b2b-55aa-4f1b-96de-4cd7911ceefe.png',
      Unit: 'túi'
    }
  ];

  // 3. Định nghĩa danh sách 4 sản phẩm cho Chó kèm 4 link ảnh tiếp theo
  const dogProducts = [
    {
      CategoryId: dogCategory.CategoryId,
      Name: 'Thức ăn hạt cho cún hạt nhỏ SmartHeart Gold',
      Description: 'Công thức đặc biệt dành riêng cho các giống chó nhỏ, giúp phát triển trí não và hệ cơ xương khỏe mạnh.',
      Price: 140000,
      Stock: 75,
      ImageUrl: 'https://res.cloudinary.com/dltxwrzsg/image/upload/v1783891978/09f2a747-5640-474a-a8a9-cfd0c819ddd3.png',
      Unit: 'túi'
    },
    {
      CategoryId: dogCategory.CategoryId,
      Name: 'Pate cho chó trưởng thành Pedigree Vị bò nấu sốt',
      Description: 'Cung cấp năng lượng dồi dào, giàu chất xơ giúp hệ tiêu hóa của cún cưng luôn ổn định.',
      Price: 38000,
      Stock: 120,
      ImageUrl: 'https://res.cloudinary.com/dltxwrzsg/image/upload/v1783891929/7659b3e0-1b0d-4ca5-b0e4-85341750311a.png',
      Unit: 'túi'
    },
    {
      CategoryId: dogCategory.CategoryId,
      Name: 'Thức ăn hạt cho cún trưởng thành Royal Canin Mini Adult',
      Description: 'Duy trì cân nặng lý tưởng, hỗ trợ sức khỏe răng miệng, dành cho giống chó từ 10 tháng đến 8 tuổi.',
      Price: 185000,
      Stock: 50,
      ImageUrl: 'https://res.cloudinary.com/dltxwrzsg/image/upload/v1783891871/134e4779-a39a-417c-9e32-08af69558804.png',
      Unit: 'túi'
    },
    {
      CategoryId: dogCategory.CategoryId,
      Name: 'Thức ăn hạt mềm hữu cơ Zenith dành cho chó con',
      Description: 'Hạt mềm dễ nhai, chiết xuất từ thịt cừu và gạo lứt, không chứa ngũ cốc gây dị ứng.',
      Price: 210000,
      Stock: 40,
      ImageUrl: 'https://res.cloudinary.com/dltxwrzsg/image/upload/v1783891918/2bec160a-0b8c-4588-9f14-5f901928daa8.png',
      Unit: 'túi'
    }
  ];

  // Gộp chung 2 danh sách lại để chạy vòng lặp chèn vào Database
  const allProducts = [...catProducts, ...dogProducts];

  for (const product of allProducts) {
    await prisma.product.create({
      data: product
    });
  }

  console.log(`=== Đã nạp thành công ${allProducts.length} sản phẩm thực tế vào Database! ===`);
}

main()
  .catch((e) => {
    console.error('Gặp lỗi khi nạp sản phẩm:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });