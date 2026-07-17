import { NextRequest, NextResponse } from 'next/server';
import { WishlistService } from '../../services/wishlist.service';
import { handleError, AppError } from '../../middleware/error.middleware';
import { TokenPayload } from '../../lib/jwt';

const wishlistService = new WishlistService();

export class WishlistController {
  async getWishlist(req: NextRequest, context: { user: TokenPayload }) {
    try {
      const userId = context.user.userId;
      const wishlist = await wishlistService.getWishlist(userId);
      return NextResponse.json(wishlist, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async addToWishlist(req: NextRequest, context: { user: TokenPayload; params: { productId: string } }) {
    try {
      const userId = context.user.userId;
      const productId = Number(context.params.productId);
      if (isNaN(productId)) {
        throw new AppError('Invalid product ID format.', 400);
      }
      const result = await wishlistService.addToWishlist(userId, productId);
      return NextResponse.json(result, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async removeFromWishlist(req: NextRequest, context: { user: TokenPayload; params: { productId: string } }) {
    try {
      const userId = context.user.userId;
      const productId = Number(context.params.productId);
      if (isNaN(productId)) {
        throw new AppError('Invalid product ID format.', 400);
      }
      const result = await wishlistService.removeFromWishlist(userId, productId);
      return NextResponse.json(result, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async checkWishlistStatus(req: NextRequest, context: { user: TokenPayload; params: { productId: string } }) {
    try {
      const userId = context.user.userId;
      const productId = Number(context.params.productId);
      if (isNaN(productId)) {
        throw new AppError('Invalid product ID format.', 400);
      }
      const result = await wishlistService.checkWishlistStatus(userId, productId);
      return NextResponse.json(result, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }
}
export default WishlistController;
