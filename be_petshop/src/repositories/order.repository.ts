import prisma from '../lib/prisma';
import { AppError } from '../middleware/error.middleware';
import { OrderStatus } from '../validators/order.validator';
import { PayOS } from '@payos/node';

function getVariantDetails(product: any, selectedVariant?: string) {
  let price = product.Price;
  let stock = product.Stock;
  if (selectedVariant && product.Variants) {
    const variants = typeof product.Variants === 'string'
      ? JSON.parse(product.Variants)
      : product.Variants;
    const variant = Array.isArray(variants)
      ? variants.find((v: any) => v.name === selectedVariant)
      : null;
    if (variant) {
      if (variant.price !== undefined) price = variant.price;
      if (variant.stock !== undefined) stock = variant.stock;
    }
  }
  return { price, stock };
}

export class OrderRepository {
  async createOrder(userId: number, shippingAddress: string, selectedCartItemIds?: number[]): Promise<any> {
    return prisma.$transaction(async (tx: any) => {
      // 0. Tối ưu phần hủy đơn cũ: Gom logic cập nhật kho
      const oldPendingOrders = await tx.order.findMany({
        where: { UserId: userId, Status: 'PENDING' },
        include: { OrderDetails: true }
      });

      for (const oldOrder of oldPendingOrders) {
        for (const detail of oldOrder.OrderDetails) {
            // Cập nhật lại kho (giả sử dùng update data: { Stock: { increment: ... } })
            // Logic JSON variant giữ nguyên nếu phức tạp
            await tx.product.update({
                where: { ProductId: detail.ProductId },
                data: { Stock: { increment: detail.Quantity } }
            });
        }
        await tx.order.update({ where: { OrderId: oldOrder.OrderId }, data: { Status: 'CANCELLED' } });
      }

      // 1. Lấy user cart items (Đã include sẵn Product)
      // Filter by selectedCartItemIds if provided, otherwise get all
      const cartItems = await tx.cartItem.findMany({
        where: {
          UserId: userId,
          ...(selectedCartItemIds && selectedCartItemIds.length > 0 ? { CartItemId: { in: selectedCartItemIds } } : {}),
        },
        include: { Product: true },
      });

      if (cartItems.length === 0) {
        throw new AppError('Giỏ hàng trống.', 400);
      }

      // 2. Validate stock và tính tổng (Logic ở memory, rất nhanh)
      let totalAmount = 0;
      for (const item of cartItems) {
        const { price, stock } = getVariantDetails(item.Product, item.SelectedVariant);
        if (stock < item.Quantity) {
          throw new AppError(`Sản phẩm ${item.Product.Name} không đủ số lượng.`, 400);
        }
        totalAmount += price * item.Quantity;
      }
      totalAmount = Number(totalAmount.toFixed(2));

      // 3. Tạo Order Header
      const order = await tx.order.create({
        data: {
          UserId: userId,
          TotalAmount: totalAmount,
          ShippingAddress: shippingAddress,
          Status: 'PENDING',
        },
      });

      // 4. BƯỚC CẢI TIẾN: Tạo Detail hàng loạt và cập nhật kho tinh gọn
      // A. Tạo chi tiết đơn hàng hàng loạt (Nhanh hơn gấp nhiều lần)
      await tx.orderDetail.createMany({
        data: cartItems.map((item: any)=> {
          const { price } = getVariantDetails(item.Product, item.SelectedVariant);
          return {
            OrderId: order.OrderId,
            ProductId: item.ProductId,
            SelectedVariant: item.SelectedVariant,
            Quantity: item.Quantity,
            UnitPrice: price,
          };
        }),
      });

      // B. Cập nhật kho (vẫn phải lặp vì cần tính toán JSON variant cụ thể)
      for (const item of cartItems) {
        let updatedVariants = item.Product.Variants;
        // Logic xử lý JSON variant
        if (item.SelectedVariant && item.Product.Variants) {
          const variants = typeof item.Product.Variants === 'string'
            ? JSON.parse(item.Product.Variants)
            : item.Product.Variants;
          
          if (Array.isArray(variants)) {
            const variant = variants.find((v: any) => v.name === item.SelectedVariant);
            if (variant) {
              variant.stock = Math.max(0, (variant.stock || 0) - item.Quantity);
            }
            updatedVariants = variants;
          }
        }

        await tx.product.update({
          where: { ProductId: item.ProductId },
          data: {
            Stock: { decrement: item.Quantity },
            Variants: updatedVariants || undefined,
          },
        });
      }

      // 5. KHÔNG xóa cart items ngay lập tức - sẽ xóa sau khi thanh toán thành công
      // Điều này đảm bảo nếu thanh toán thất bại, user vẫn có thể thử lại
      // Cart items sẽ được xóa trong payment webhook khi thanh toán thành công

      return order;
    }, {
      maxWait: 10000,
      timeout: 30000, // Giữ timeout 30s
    });
  }

  async findAll(userId?: number) {
    const orders = await prisma.order.findMany({
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
        OrderDetails: {
          include: {
            Product: true,
          },
        },
      },
    });

    // Tự động kiểm tra và đồng bộ trạng thái PENDING với PayOS (Self-healing fallback)
    const pendingOrders = orders.filter(o => o.Status === 'PENDING' && o.OrderCode);
    if (pendingOrders.length > 0 && process.env.PAYOS_CLIENT_ID) {
      const payos = new PayOS({
        clientId: process.env.PAYOS_CLIENT_ID,
        apiKey: process.env.PAYOS_API_KEY || '',
        checksumKey: process.env.PAYOS_CHECKSUM_KEY || '',
      });

      await Promise.all(
        pendingOrders.map(async (order) => {
          try {
            const payosOrder = await payos.paymentRequests.get(order.OrderCode!);
            if (payosOrder) {
              if (payosOrder.status === 'PAID') {
                await this.updateStatus(order.OrderId, 'PAID');
                order.Status = 'PAID';
              } else if (payosOrder.status === 'CANCELLED' || payosOrder.status === 'EXPIRED') {
                await this.updateStatus(order.OrderId, 'CANCELLED');
                order.Status = 'CANCELLED';
              }
            }
          } catch (err) {
            // Im lặng nếu lỗi (link chưa được thanh toán hoặc hết hạn trên PayOS)
          }
        })
      );
    }

    return orders;
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
    return prisma.$transaction(async (tx: any) => {
      // 1. Lấy thông tin đơn hàng hiện tại
      const order = await tx.order.findUnique({
        where: { OrderId: orderId },
        include: { OrderDetails: true },
      });

      if (!order) {
        throw new AppError('Order not found.', 404);
      }

      // 2. Nếu chuyển từ PENDING sang CANCELLED, hoàn trả số lượng sản phẩm vào kho
      if (order.Status === 'PENDING' && status === 'CANCELLED') {
        for (const detail of order.OrderDetails) {
          const product = await tx.product.findUnique({
            where: { ProductId: detail.ProductId },
          });

          let updatedVariants = product?.Variants;
          if (product && detail.SelectedVariant && product.Variants) {
            const variants = typeof product.Variants === 'string'
              ? JSON.parse(product.Variants)
              : product.Variants;
            if (Array.isArray(variants)) {
              const variant = variants.find((v: any) => v.name === detail.SelectedVariant);
              if (variant) {
                variant.stock = (variant.stock || 0) + detail.Quantity;
              }
              updatedVariants = variants;
            }
          }

          await tx.product.update({
            where: { ProductId: detail.ProductId },
            data: {
              Stock: {
                increment: detail.Quantity,
              },
              Variants: updatedVariants || undefined,
            },
          });
        }
      }

      // 3. Cập nhật trạng thái đơn hàng
      return tx.order.update({
        where: { OrderId: orderId },
        data: { Status: status },
      });
    });
  }
}
