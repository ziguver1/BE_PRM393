const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('=== Bắt đầu nạp dữ liệu nhóm bộ lọc (Filter Groups & Options) ===');

  // 1. Nhóm bộ lọc: Thương hiệu
  await prisma.filterGroup.create({
    data: {
      Name: 'Thương hiệu',
      Description: 'Các thương hiệu thức ăn và phụ kiện nổi tiếng',
      Options: {
        create: [
          { Value: 'Royal Canin' },
          { Value: 'Whiskas' },
          { Value: 'Pedigree' },
          { Value: 'SmartHeart' },
          { Value: 'Me-O' },
          { Value: 'Catsrang' }
        ]
      }
    }
  });

  // 2. Nhóm bộ lọc: Giai đoạn độ tuổi
  await prisma.filterGroup.create({
    data: {
      Name: 'Độ tuổi',
      Description: 'Phù hợp với từng giai đoạn phát triển của thú cưng',
      Options: {
        create: [
          { Value: 'Thú cưng nhỏ (Puppy / Kitten)' },
          { Value: 'Trưởng thành (Adult)' },
          { Value: 'Cao tuổi / Triệt sản (Senior)' }
        ]
      }
    }
  });

  // 3. Nhóm bộ lọc: Hương vị (Dành cho Thức ăn & Bánh thưởng)
  await prisma.filterGroup.create({
    data: {
      Name: 'Hương vị',
      Description: 'Mùi vị kích thích vị giác của boss',
      Options: {
        create: [
          { Value: 'Vị Thịt Gà (Chicken)' },
          { Value: 'Vị Thịt Bò (Beef)' },
          { Value: 'Vị Cá Hồi (Salmon)' },
          { Value: 'Vị Cá Ngừ (Tuna)' }
        ]
      }
    }
  });

  // 4. Nhóm bộ lọc: Kích cỡ / Thể trạng (Dành cho Phụ kiện quần áo hoặc hạt đặc thù)
  await prisma.filterGroup.create({
    data: {
      Name: 'Kích cỡ Pet',
      Description: 'Phân loại theo kích thước cơ thể thú cưng',
      Options: {
        create: [
          { Value: 'Giống nhỏ (Small Breed)' },
          { Value: 'Giống lớn (Large Breed)' }
        ]
      }
    }
  });

  // 5. Nhóm bộ lọc: Chức năng dinh dưỡng sức khỏe
  await prisma.filterGroup.create({
    data: {
      Name: 'Tính năng sức khỏe',
      Description: 'Hỗ trợ điều trị hoặc bổ sung thể trạng đặc biệt',
      Options: {
        create: [
          { Value: 'Mượt lông & Đẹp da' },
          { Value: 'Tiêu búi lông (Hairball Control)' },
          { Value: 'Hỗ trợ hệ tiêu hóa nhạy cảm' },
          { Value: 'Tăng cân & Phát triển cơ bắp' }
        ]
      }
    }
  });

  console.log('=== Nạp thành công toàn bộ nhóm bộ lọc và các thuộc tính con vào DB! ===');
}

main()
  .catch((e) => {
    console.error('Gặp lỗi khi nạp filter:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });