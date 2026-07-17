import { OrderRepository } from '../repositories/order.repository';
import { CreateOrderInput, OrderStatus } from '../validators/order.validator';
import { AppError } from '../middleware/error.middleware';
import { NotificationService } from './notification.service';

const orderRepository = new OrderRepository();

async function reverseGeocode(lat: number, lng: number): Promise<string> {
  const url = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json&accept-language=vi,en`;
  console.log(`DEBUG: Geocoding Request URL: ${url}`);
  try {
    const response = await fetch(url, {
      cache: 'no-store',
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }
    });
    console.log(`DEBUG: Geocoding HTTP status: ${response.status}`);
    const text = await response.text();
    console.log(`DEBUG: Geocoding Full response body: ${text}`);

    if (!response.ok) {
      throw new Error(`HTTP Error ${response.status}: ${text}`);
    }

    const data = JSON.parse(text);
    if (data && data.display_name) {
      console.log(`DEBUG: Geocoding Parsed address: ${data.display_name}`);
      return data.display_name;
    } else {
      console.log('DEBUG: Geocoding returned no display_name field.');
    }
  } catch (error: any) {
    console.error(`DEBUG: Reverse geocoding failed: ${error.message || error}`);
  }
  return `Latitude: ${lat}, Longitude: ${lng}`;
}

export class OrderService {
  async create(userId: number, input: CreateOrderInput) {
    const shippingAddress = await reverseGeocode(input.shippingLatitude, input.shippingLongitude);
    return orderRepository.createOrder(
      userId,
      shippingAddress,
      input.selectedCartItemIds,
      input.shippingLatitude,
      input.shippingLongitude
    );
  }

  async getAll(userId: number, role: string) {
    if (role === 'ADMIN') {
      return orderRepository.findAll();
    }
    return orderRepository.findAll(userId);
  }

  async getById(userId: number, role: string, orderId: number) {
    const order = await orderRepository.findById(orderId);
    if (!order) {
      throw new AppError('Order not found.', 404);
    }

    if (role !== 'ADMIN' && order.UserId !== userId) {
      throw new AppError('Forbidden: Access denied to this order.', 403);
    }

    return order;
  }

  async updateStatus(orderId: number, status: OrderStatus, userId?: number, role?: string) {
    const order = await orderRepository.findById(orderId);
    if (!order) {
      throw new AppError('Order not found.', 404);
    }

    // Role-based validation if role is specified (from client controllers)
    if (role && role !== 'ADMIN') {
      if (order.UserId !== userId) {
        throw new AppError('Forbidden: Access denied to this order.', 403);
      }
      if (status !== 'RECEIVED') {
        throw new AppError('Forbidden: Customers can only confirm receipt of their orders.', 403);
      }
      if (order.Status !== 'DELIVERED') {
        throw new AppError('Forbidden: Can only confirm receipt for orders that are already delivered.', 403);
      }
    } else if (role === 'ADMIN') {
      // Admin state machine transition checks
      if (status === 'SHIPPING' && order.Status !== 'PAID') {
        throw new AppError('Admin can only start delivery for PAID orders.', 400);
      }
      if (order.Status === 'PAID' && (status === 'DELIVERED' || status === 'RECEIVED')) {
        throw new AppError('Admin cannot transition PAID orders directly to DELIVERED or RECEIVED.', 400);
      }
    }

    const result = await orderRepository.updateStatus(orderId, status);

    // Gửi thông báo khi Admin bắt đầu giao hàng (PAID -> SHIPPING)
    if (order.Status === 'PAID' && status === 'SHIPPING') {
      new NotificationService().sendOrderNotification(
        order.UserId,
        orderId,
        'ORDER_SHIPPING_STARTED',
        '🚚 Đơn hàng đang được giao',
        'Đơn hàng của bạn đã được cửa hàng bàn giao cho đơn vị vận chuyển. Bạn có thể theo dõi hành trình giao hàng ngay bây giờ.'
      ).catch((err: any) => console.error('FCM SHIPPING Error:', err));
    }

    return result;
  }

  async getTracking(userId: number, role: string, orderId: number) {
    const order = await orderRepository.findById(orderId);
    if (!order) {
      throw new AppError('Order not found.', 404);
    }
    if (role !== 'ADMIN' && order.UserId !== userId) {
      throw new AppError('Forbidden: Access denied to this order.', 403);
    }
    return orderRepository.getTracking(orderId);
  }
}
export default OrderService;
