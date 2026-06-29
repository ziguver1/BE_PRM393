import { vi, describe, it, expect, beforeEach } from 'vitest';
import { CartService } from '../services/cart.service';
import prisma from '../lib/prisma';

vi.mock('../lib/prisma', () => ({
  default: {
    cartItem: {
      findMany: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
      delete: vi.fn(),
    },
    product: {
      findUnique: vi.fn(),
    },
  },
}));

describe('CartService unit tests', () => {
  let cartService: CartService;

  beforeEach(() => {
    vi.clearAllMocks();
    cartService = new CartService();
  });

  describe('getCart', () => {
    it('should fetch cart items and calculate total correctly', async () => {
      const mockCartItems = [
        {
          CartItemId: 1,
          UserId: 10,
          ProductId: 20,
          Quantity: 3,
          Product: {
            ProductId: 20,
            Name: 'Dog Collar',
            Price: 12.5,
            Stock: 15,
          },
        },
        {
          CartItemId: 2,
          UserId: 10,
          ProductId: 21,
          Quantity: 1,
          Product: {
            ProductId: 21,
            Name: 'Squeaky Ball',
            Price: 5.95,
            Stock: 20,
          },
        },
      ];

      vi.mocked(prisma.cartItem.findMany).mockResolvedValue(mockCartItems as any);

      const res = await cartService.getCart(10);

      // (12.5 * 3) + 5.95 = 37.5 + 5.95 = 43.45
      expect(res.total).toBe(43.45);
      expect(res.items).toHaveLength(2);
    });
  });

  describe('addItem', () => {
    it('should throw an error if total quantity exceeds stock levels', async () => {
      const mockProduct = {
        ProductId: 30,
        Name: 'Kitten Milk',
        Price: 10.0,
        Stock: 4,
      };
      vi.mocked(prisma.product.findUnique).mockResolvedValue(mockProduct as any);
      vi.mocked(prisma.cartItem.findUnique).mockResolvedValue(null);

      await expect(
        cartService.addItem(10, {
          ProductId: 30,
          Quantity: 5,
        })
      ).rejects.toThrow('Cannot add product to cart.');
    });

    it('should update existing item quantity if product is already in cart', async () => {
      const mockProduct = {
        ProductId: 30,
        Name: 'Kitten Milk',
        Price: 10.0,
        Stock: 10,
      };
      const existingCartItem = {
        CartItemId: 5,
        UserId: 10,
        ProductId: 30,
        Quantity: 2,
      };

      vi.mocked(prisma.product.findUnique).mockResolvedValue(mockProduct as any);
      vi.mocked(prisma.cartItem.findUnique).mockResolvedValue(existingCartItem as any);
      vi.mocked(prisma.cartItem.update).mockResolvedValue({} as any);

      await cartService.addItem(10, {
        ProductId: 30,
        Quantity: 3,
      });

      expect(prisma.cartItem.update).toHaveBeenCalledWith({
        where: { CartItemId: 5 },
        data: { Quantity: 5 },
        include: { Product: true },
      });
    });
  });
});
