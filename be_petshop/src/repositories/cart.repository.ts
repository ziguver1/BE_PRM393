import prisma from '../lib/prisma';

export class CartRepository {
  async findByUserId(userId: number) {
    return prisma.cartItem.findMany({
      where: { UserId: userId },
      include: {
        Product: true,
      },
    });
  }

  async findById(cartItemId: number) {
    return prisma.cartItem.findUnique({
      where: { CartItemId: cartItemId },
      include: {
        Product: true,
      },
    });
  }

  async findItemByUserAndProduct(userId: number, productId: number) {
    return prisma.cartItem.findUnique({
      where: {
        UserId_ProductId: {
          UserId: userId,
          ProductId: productId,
        },
      },
    });
  }

  async addItem(userId: number, productId: number, quantity: number) {
    return prisma.cartItem.create({
      data: {
        UserId: userId,
        ProductId: productId,
        Quantity: quantity,
      },
      include: {
        Product: true,
      },
    });
  }

  async updateItem(cartItemId: number, quantity: number) {
    return prisma.cartItem.update({
      where: { CartItemId: cartItemId },
      data: { Quantity: quantity },
      include: {
        Product: true,
      },
    });
  }

  async removeItem(cartItemId: number) {
    return prisma.cartItem.delete({
      where: { CartItemId: cartItemId },
    });
  }

  async clearCart(userId: number) {
    return prisma.cartItem.deleteMany({
      where: { UserId: userId },
    });
  }
}
