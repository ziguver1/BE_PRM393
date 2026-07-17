import prisma from '../lib/prisma';
import { AppError } from '../middleware/error.middleware';
import { OrderStatus } from '../validators/order.validator';
import { PayOS } from '@payos/node';
import { NotificationService } from '../services/notification.service';

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
  async createOrder(userId: number, shippingAddress: string, selectedCartItemIds?: number[], userLat?: number, userLng?: number): Promise<any> {
    console.log('DEBUG: selectedCartItemIds received:', selectedCartItemIds);
    console.log('DEBUG: user coordinates received:', { userLat, userLng });
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

      console.log('DEBUG: Filtered cart items count:', cartItems.length);
      console.log('DEBUG: Cart item IDs:', cartItems.map((item: any) => item.CartItemId));

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
          UserLat: userLat,
          UserLng: userLng,
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

    // Tự động đồng bộ các đơn hàng SHIPPING đã hết thời gian giao sang DELIVERED
    const resolvedOrders = await Promise.all(
      orders.map(o => this.resolveOrderStatus(o))
    );

    // Tự động kiểm tra và đồng bộ trạng thái PENDING với PayOS (Self-healing fallback)
    const pendingOrders = resolvedOrders.filter(o => o.Status === 'PENDING' && o.OrderCode);
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

    return resolvedOrders;
  }

  async findById(orderId: number) {
    const order = await prisma.order.findUnique({
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
    if (!order) return null;
    return this.resolveOrderStatus(order);
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

      // 2.1. Ngăn chặn rollback trạng thái (chỉ cho phép chuyển tiếp trạng thái tiến lên)
      const STATUS_ORDER = ['PENDING', 'PAID', 'PROCESSING', 'SHIPPING', 'DELIVERED', 'RECEIVED'];
      const currentIndex = STATUS_ORDER.indexOf(order.Status);
      const newIndex = STATUS_ORDER.indexOf(status);

      if (currentIndex !== -1 && newIndex !== -1 && newIndex < currentIndex) {
        throw new AppError(`Không thể thay đổi trạng thái từ ${order.Status} ngược lại ${status}.`, 400);
      }

      // 2.2. Nếu chuyển từ PENDING sang CANCELLED, hoàn trả số lượng sản phẩm vào kho
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

        // Chỉ cập nhật trạng thái, không thực hiện thêm logic nào khác
        return tx.order.update({
          where: { OrderId: orderId },
          data: { Status: status },
        });
      }

      // 3. Chỉ khi chuyển sang SHIPPING mới gọi OSRM API
      if (status === 'SHIPPING') {
        if (!order.UserLat || !order.UserLng) {
          throw new AppError('Không thể chuyển giao hàng: Khách hàng chưa thiết lập tọa độ giao hàng.', 400);
        }

        // Tọa độ cửa hàng cố định theo thiết kế mới
        const STORE_LAT = 10.8660;
        const STORE_LNG = 106.7951;
        
        console.log('DEBUG: Calling OSRM API with store coordinates - Lat:', STORE_LAT, 'Lng:', STORE_LNG);

        // Gọi OSRM API
        const osrmUrl = `http://router.project-osrm.org/route/v1/driving/${STORE_LNG},${STORE_LAT};${order.UserLng},${order.UserLat}?overview=full&geometries=geojson`;
        
        let formattedRoutePoints: any[] = [];
        try {
          const response = await fetch(osrmUrl);
          if (!response.ok) {
            throw new Error(`OSRM API response error: ${response.status}`);
          }
          const osrmData = await response.json();
          const routePoints = osrmData.routes?.[0]?.geometry?.coordinates || [];
          if (routePoints.length === 0) {
            throw new Error('OSRM API returned empty route points list');
          }
          
          // Chuyển đổi từ [lng, lat] sang {lat, lng}
          formattedRoutePoints = routePoints.map((coord: number[]) => ({
            lat: coord[1],
            lng: coord[0],
          }));
        } catch (error: any) {
          console.error('Lỗi gọi OSRM:', error);
          throw new AppError('Không thể tạo lộ trình giao hàng từ OSRM API. Vui lòng thử lại sau.', 400);
        }

        // Cập nhật trạng thái và lưu route_points, ShippingStartedAt vào DB
        const updatedOrder = await tx.order.update({
          where: { OrderId: orderId },
          data: {
            Status: status,
            RoutePoints: formattedRoutePoints,
            ShippingStartedAt: new Date(), // Ghi nhận mốc thời gian bắt đầu giao hàng
          },
        });
        console.log('DEBUG: Order updated successfully to SHIPPING with RoutePoints and ShippingStartedAt');
        return updatedOrder;
      }

      // 5. Cập nhật trạng thái đơn hàng (cho các trạng thái khác)
      return tx.order.update({
        where: { OrderId: orderId },
        data: { Status: status },
      });
    });
  }

  // Tự động giải quyết trạng thái đơn hàng theo mốc thời gian giao hàng thực tế
  async resolveOrderStatus(order: any, tx?: any) {
    if (order.Status === 'SHIPPING' && order.ShippingStartedAt !== null && order.ShippingStartedAt !== undefined) {
      const shippingDate = new Date(order.ShippingStartedAt);
      if (isNaN(shippingDate.getTime())) {
        return order;
      }
      const elapsedMs = Date.now() - shippingDate.getTime();
      const duration = 60000; // Mô phỏng giao hàng trong 60 giây
      if (elapsedMs >= duration) {
        const db = tx || prisma;
        const updated = await db.order.update({
          where: { OrderId: order.OrderId },
          data: { Status: 'DELIVERED' },
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
        console.log(`DEBUG: Order #${order.OrderId} automatically transitioned to DELIVERED (duration reached).`);
        new NotificationService().sendOrderNotification(
          order.UserId,
          order.OrderId,
          'ORDER_DELIVERED',
          '📦 Đơn hàng đã được giao',
          'Đơn hàng của bạn đã được giao thành công. Vui lòng xác nhận đã nhận hàng để hoàn tất đơn hàng.'
        ).catch((err: any) => console.error('FCM DELIVERED Error:', err));
        return updated;
      }
    }
    return order;
  }

  // Lấy chi tiết thông tin theo dõi và simulation của đơn hàng
  async getTracking(orderId: number) {
    const rawOrder = await prisma.order.findUnique({
      where: { OrderId: orderId },
    });

    if (!rawOrder) {
      throw new AppError('Order not found.', 404);
    }

    const order = await this.resolveOrderStatus(rawOrder);

    const points = order.RoutePoints
      ? (typeof order.RoutePoints === 'string'
          ? JSON.parse(order.RoutePoints)
          : order.RoutePoints) as any[]
      : [];

    if (order.Status !== 'SHIPPING' && order.Status !== 'DELIVERED' && order.Status !== 'RECEIVED') {
      return {
        status: order.Status,
        progress: 0,
        currentIndex: 0,
        routePoints: points,
        driver: null,
      };
    }

    let progress = 0;
    let currentIndex = 0;

    if (order.Status === 'DELIVERED' || order.Status === 'RECEIVED') {
      progress = 100;
      currentIndex = points.length > 0 ? points.length - 1 : 0;
    } else if (order.Status === 'SHIPPING' && order.ShippingStartedAt !== null && order.ShippingStartedAt !== undefined) {
      const shippingDate = new Date(order.ShippingStartedAt);
      if (!isNaN(shippingDate.getTime())) {
        const elapsedMs = Date.now() - shippingDate.getTime();
        const duration = 60000; // 60s giao hàng
        progress = Math.min(100, Math.round((elapsedMs / duration) * 100));
        currentIndex = Math.min(points.length - 1, Math.round((progress / 100) * (points.length - 1)));
      }
    }

    return {
      status: order.Status,
      progress,
      currentIndex,
      routePoints: points,
      driver: {
        name: 'PetShop Delivery',
        phone: '0909000000',
      },
    };
  }
}
