const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const orderId = 43;
  console.log(`=== CHECKING ORDER #${orderId} ===`);
  const order = await prisma.order.findUnique({
    where: { OrderId: orderId },
    include: {
      User: true
    }
  });

  if (!order) {
    console.log(`Order #${orderId} not found in the database.`);
    return;
  }

  console.log('Order Details:');
  console.log(`- Status: "${order.Status}"`);
  console.log(`- UserId: ${order.UserId}`);
  console.log(`- TotalAmount: ${order.TotalAmount}`);
  console.log(`- ShippingAddress: "${order.ShippingAddress}"`);
  console.log(`- User FCM Token: "${order.User.fcmToken}"`);

  console.log('\nNotification Logs for this Order:');
  const logs = await prisma.notificationLog.findMany({
    where: { OrderId: orderId }
  });
  console.log(logs);

  console.log('\nNotifications for this User:');
  const notifs = await prisma.notification.findMany({
    where: { UserId: order.UserId }
  });
  console.log(notifs);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
