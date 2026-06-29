import prisma from '../lib/prisma';
import { AppError } from '../middleware/error.middleware';
import { OrderStatus } from '../validators/order.validator';

export class OrderRepository {
  async createOrder(userId: number, shippingAddress: string): Promise<any> {
    return prisma.$transaction(async (tx: any) => {
      // 1. Get user cart items
      const cartItems = await tx.cartItem.findMany({
        where: { UserId: userId },
        include: { Product: true },
      });

      if (cartItems.length === 0) {
        throw new AppError('Cannot place order with an empty cart.', 400);
      }

      // 2. Validate stock and calculate totals
      let totalAmount = 0;
      for (const item of cartItems) {
        if (item.Product.Stock < item.Quantity) {
          throw new AppError(`Insufficient stock for product: ${item.Product.Name}. Available: ${item.Product.Stock}`, 400);
        }
        totalAmount += item.Product.Price * item.Quantity;
      }
      totalAmount = Number(totalAmount.toFixed(2));

      // 3. Create the order header
      const order = await tx.order.create({
        data: {
          UserId: userId,
          TotalAmount: totalAmount,
          ShippingAddress: shippingAddress,
          Status: 'PENDING',
        },
      });

      // 4. Create order line details and decrement product stock
      for (const item of cartItems) {
        await tx.orderDetail.create({
          data: {
            OrderId: order.OrderId,
            ProductId: item.ProductId,
            Quantity: item.Quantity,
            UnitPrice: item.Product.Price,
          },
        });


        await tx.product.update({
          where: { ProductId: item.ProductId },
          data: {
            Stock: item.Product.Stock - item.Quantity,
          },
        });
      }

      // 5. Clear cart
      await tx.cartItem.deleteMany({
        where: { UserId: userId },
      });

      return order;
    });
  }

  async findAll(userId?: number) {
    return prisma.order.findMany({
      where: userId ? { UserId: userId } : {},
      orderBy: { CreatedAt: 'desc' },
      include: {
        User: {
          select: {
            UserId: true,
            FullName: true,
            Email: true,
          },
        },
      },
    });
  }

  async findById(orderId: number) {
    return prisma.order.findUnique({
      where: { OrderId: orderId },
      include: {
        User: {
          select: {
            UserId: true,
            FullName: true,
            Email: true,
            Phone: true,
          },
        },
        OrderDetails: {
          include: {
            Product: true,
          },
        },
      },
    });
  }

  async updateStatus(orderId: number, status: OrderStatus) {
    return prisma.order.update({
      where: { OrderId: orderId },
      data: { Status: status },
    });
  }
}
