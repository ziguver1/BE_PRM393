const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('=== Bắt đầu tạo tài khoản Admin ===');

  // Hash password
  const password = 'admin123';
  const hashedPassword = await bcrypt.hash(password, 10);

  // Check if admin already exists
  const existingAdmin = await prisma.user.findUnique({
    where: { Email: 'admin@petshop.com' },
  });

  if (existingAdmin) {
    console.log('=== Tài khoản Admin đã tồn tại ===');
    console.log('Email: admin@petshop.com');
    console.log('Password: admin123');
    return;
  }

  // Create admin user
  const admin = await prisma.user.create({
    data: {
      FullName: 'Admin User',
      Email: 'admin@petshop.com',
      PasswordHash: hashedPassword,
      Phone: '0123456789',
      Role: 'ADMIN',
    },
  });

  console.log('=== Tạo tài khoản Admin thành công ===');
  console.log('Email:', admin.Email);
  console.log('Password: admin123');
  console.log('Role:', admin.Role);
}

main()
  .catch((e) => {
    console.error('Lỗi trong quá trình seed admin:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
