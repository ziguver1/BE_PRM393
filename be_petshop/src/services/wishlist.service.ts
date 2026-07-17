import { PrismaClient } from '@prisma/client';
import { AppError } from '../middleware/error.middleware';

const prisma = new PrismaClient();

export class WishlistService {
  async getWishlist(userId: number) {
    const items = await prisma.wishlist.findMany({
      where: { UserId: userId },
      include: {
        Product: {
          include: {
            Category: true,
            Images: true,
            ProductVariants: true,
          },
        },
      },
      orderBy: { CreatedAt: 'desc' },
    });

    return items.map((item) => {
      const p = item.Product;
      return {
        ...p,
        isWishlisted: true,
        IsWishlisted: true,
      };
    });
  }

  async addToWishlist(userId: number, productId: number) {
    // Verify product exists
    const product = await prisma.product.findUnique({
      where: { ProductId: productId },
    });

    if (!product) {
      throw new AppError('Product not found.', 404);
    }

    // Check if already wishlisted (idempotent check)
    const existing = await prisma.wishlist.findUnique({
      where: {
        UserId_ProductId: { UserId: userId, ProductId: productId },
      },
    });

    if (existing) {
      return { success: true, message: 'Product already in wishlist.', wishlist: existing };
    }

    const created = await prisma.wishlist.create({
      data: { UserId: userId, ProductId: productId },
    });

    return { success: true, message: 'Product added to wishlist.', wishlist: created };
  }

  async removeFromWishlist(userId: number, productId: number) {
    await prisma.wishlist.deleteMany({
      where: { UserId: userId, ProductId: productId },
    });
    return { success: true, message: 'Product removed from wishlist.' };
  }

  async checkWishlistStatus(userId: number, productId: number) {
    const existing = await prisma.wishlist.findUnique({
      where: {
        UserId_ProductId: { UserId: userId, ProductId: productId },
      },
    });
    return { isWishlisted: !!existing };
  }
}
