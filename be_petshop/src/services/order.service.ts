import { OrderRepository } from '../repositories/order.repository';
import { CreateOrderInput, OrderStatus } from '../validators/order.validator';
import { AppError } from '../middleware/error.middleware';

const orderRepository = new OrderRepository();

export class OrderService {
  async create(userId: number, input: CreateOrderInput) {
    return orderRepository.createOrder(userId, input.ShippingAddress, input.selectedCartItemIds);
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

  async updateStatus(orderId: number, status: OrderStatus) {
    const order = await orderRepository.findById(orderId);
    if (!order) {
      throw new AppError('Order not found.', 404);
    }
    return orderRepository.updateStatus(orderId, status);
  }
}
export default OrderService;
