import { NextRequest, NextResponse } from 'next/server';
import { OrderService } from '../../services/order.service';
import { createOrderSchema, updateOrderStatusSchema } from '../../validators/order.validator';
import { handleError, AppError } from '../../middleware/error.middleware';
import { TokenPayload } from '../../lib/jwt';

const orderService = new OrderService();

export class OrdersController {
  async create(req: NextRequest, context: { user: TokenPayload }) {
    try {
      const userId = context.user.userId;
      const body = await req.json();
      const validated = createOrderSchema.parse(body);
      const order = await orderService.create(userId, validated);
      return NextResponse.json(order, { status: 201 });
    } catch (error) {
      return handleError(error);
    }
  }

  async getAll(req: NextRequest, context: { user: TokenPayload }) {
    try {
      const userId = context.user.userId;
      const role = context.user.role;
      const orders = await orderService.getAll(userId, role);
      return NextResponse.json(orders, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async getById(req: NextRequest, context: { user: TokenPayload; params: { id: string } }) {
    try {
      const userId = context.user.userId;
      const role = context.user.role;
      const orderId = Number(context.params.id);
      if (isNaN(orderId)) {
        throw new AppError('Invalid order ID format.', 400);
      }
      const order = await orderService.getById(userId, role, orderId);
      return NextResponse.json(order, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async updateStatus(req: NextRequest, context: { user: TokenPayload; params: { id: string } }) {
    try {
      const orderId = Number(context.params.id);
      if (isNaN(orderId)) {
        throw new AppError('Invalid order ID format.', 400);
      }
      const body = await req.json();
      // Handle both uppercase "Status" and lowercase "status" keys
      const rawStatus = body.Status || body.status;
      const validated = updateOrderStatusSchema.parse({ Status: rawStatus });
      const updatedOrder = await orderService.updateStatus(
        orderId, 
        validated.Status, 
        context.user.userId, 
        context.user.role
      );
      return NextResponse.json(updatedOrder, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async getTracking(req: NextRequest, context: { user: TokenPayload; params: { id: string } }) {
    try {
      const userId = context.user.userId;
      const role = context.user.role;
      const orderId = Number(context.params.id);
      if (isNaN(orderId)) {
        throw new AppError('Invalid order ID format.', 400);
      }
      const tracking = await orderService.getTracking(userId, role, orderId);
      return NextResponse.json(tracking, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }
}
export default OrdersController;
