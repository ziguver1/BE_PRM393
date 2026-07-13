const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('=== Bắt đầu liên kết Sản phẩm với các Bộ lọc (ProductFilter) ===');

  // 1. Lấy toàn bộ Sản phẩm và các Filter Option hiện có trong DB
  const products = await prisma.product.findMany();
  const options = await prisma.filterOption.findMany();

  if (products.length === 0 || options.length === 0) {
    console.error('Lỗi: Thiếu dữ liệu Product hoặc FilterOption. Hãy chạy các file seed trước đó!');
    return;
  }

  // Hàm tiện ích để tìm ID của Option dựa trên từ khóa trong tên
  const findOptionId = (keyword) => {
    const found = options.find(opt => opt.Value.toLowerCase().includes(keyword.toLowerCase()));
    return found ? found.FilterOptionId : null;
  };

  // 2. Duyệt qua từng sản phẩm để phân tích từ khóa và tạo liên kết
  let count = 0;
  for (const prod of products) {
    const productName = prod.Name;
    const linkedOptionIds = [];

    // --- A. Bắt bộ lọc Thương hiệu (Brand) ---
    if (productName.includes('Whiskas')) linkedOptionIds.push(findOptionId('Whiskas'));
    if (productName.includes('Royal Canin')) linkedOptionIds.push(findOptionId('Royal Canin'));
    if (productName.includes('Catsrang')) linkedOptionIds.push(findOptionId('Catsrang'));
    if (productName.includes('Me-O')) linkedOptionIds.push(findOptionId('Me-O'));
    if (productName.includes('SmartHeart')) linkedOptionIds.push(findOptionId('SmartHeart'));
    if (productName.includes('Pedigree')) linkedOptionIds.push(findOptionId('Pedigree'));
    // (Món Zenith nếu chưa có thương hiệu trong bộ lọc thì tạm bỏ qua hoặc gán nhãn khác)

    // --- B. Bắt bộ lọc Độ tuổi (Age) ---
    if (productName.includes('trưởng thành') || productName.includes('Adult')) {
      linkedOptionIds.push(findOptionId('Trưởng thành'));
    }
    if (productName.includes('con') || productName.includes('Babycat')) {
      linkedOptionIds.push(findOptionId('Thú cưng nhỏ'));
    }

    // --- C. Bắt bộ lọc Hương vị (Flavor) ---
    if (productName.includes('cá biển') || productName.includes('Cá biển')) {
      linkedOptionIds.push(findOptionId('Cá Ngừ') || findOptionId('Cá Hồi')); // map tạm vào nhóm cá
    }
    if (productName.includes('cá hồi') || productName.includes('Cá hồi')) {
      linkedOptionIds.push(findOptionId('Cá Hồi'));
    }
    if (productName.includes('bò')) {
      linkedOptionIds.push(findOptionId('Beef'));
    }

    // --- D. Bắt bộ lọc Tính năng sức khỏe ---
    if (productName.includes('Babycat') || productName.includes('con')) {
      linkedOptionIds.push(findOptionId('Phát triển cơ bắp')); // Mèo con/chó con cần phát triển cơ bắp
    }

    // Lọc bỏ các giá trị null (nếu từ khóa không khớp option nào)
    const validOptionIds = [...new Set(linkedOptionIds.filter(id => id !== null))];

    // 3. Tiến hành chèn dữ liệu vào bảng ProductFilter
    for (const optionId of validOptionIds) {
      try {
        await prisma.productFilter.create({
          data: {
            ProductId: prod.ProductId,
            FilterOptionId: optionId
          }
        });
        count++;
      } catch (error) {
        // Tránh lỗi nếu chạy lại file seed bị trùng khóa chính kép
        console.log(`Liên kết đã tồn tại cho Product ID ${prod.ProductId} - Option ID ${optionId}`);
      }
    }
  }

  console.log(`=== Đã nạp thành công ${count} bản ghi liên kết bộ lọc vào DB! ===`);
}

main()
  .catch((e) => {
    console.error('Gặp lỗi khi liên kết bộ lọc:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });