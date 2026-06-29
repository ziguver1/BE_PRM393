import { NextRequest, NextResponse } from 'next/server';
import { CartService } from '../../services/cart.service';
import { addCartItemSchema, updateCartItemSchema } from '../../validators/cart.validator';
import { handleError, AppError } from '../../middleware/error.middleware';
import { TokenPayload } from '../../lib/jwt';

const cartService = new CartService();

export class CartsController {
  async getCart(req: NextRequest, context: { user: TokenPayload }) {
    try {
      const userId = context.user.userId;
      const cart = await cartService.getCart(userId);
      return NextResponse.json(cart, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async addItem(req: NextRequest, context: { user: TokenPayload }) {
    try {
      const userId = context.user.userId;
      const body = await req.json();
      const validated = addCartItemSchema.parse(body);
      const cartItem = await cartService.addItem(userId, validated);
      return NextResponse.json(cartItem, { status: 201 });
    } catch (error) {
      return handleError(error);
    }
  }

  async updateItem(req: NextRequest, context: { user: TokenPayload; params: { id: string } }) {
    try {
      const userId = context.user.userId;
      const cartItemId = Number(context.params.id);
      if (isNaN(cartItemId)) {
        throw new AppError('Invalid cart item ID format.', 400);
      }
      const body = await req.json();
      const validated = updateCartItemSchema.parse(body);
      const updatedItem = await cartService.updateItem(userId, cartItemId, validated);
      return NextResponse.json(updatedItem, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async removeItem(req: NextRequest, context: { user: TokenPayload; params: { id: string } }) {
    try {
      const userId = context.user.userId;
      const cartItemId = Number(context.params.id);
      if (isNaN(cartItemId)) {
        throw new AppError('Invalid cart item ID format.', 400);
      }
      await cartService.removeItem(userId, cartItemId);
      return NextResponse.json(
        { message: 'Item removed from cart successfully.' },
        { status: 200 }
      );
    } catch (error) {
      return handleError(error);
    }
  }
}
export default CartsController;
