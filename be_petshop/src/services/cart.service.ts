import { CartRepository } from '../repositories/cart.repository';
import { ProductRepository } from '../repositories/product.repository';
import { AddCartItemInput, UpdateCartItemInput } from '../validators/cart.validator';
import { AppError } from '../middleware/error.middleware';

const cartRepository = new CartRepository();
const productRepository = new ProductRepository();

export class CartService {
  async getCart(userId: number) {
    const items = await cartRepository.findByUserId(userId);
    const total = items.reduce((sum: number, item: any) => sum + item.Quantity * item.Product.Price, 0);
    return {
      items,
      total: Number(total.toFixed(2)),
    };
  }

  async addItem(userId: number, input: AddCartItemInput) {
    const product = await productRepository.findById(input.ProductId);
    if (!product) {
      throw new AppError('Product not found.', 404);
    }

    const existing = await cartRepository.findItemByUserAndProduct(userId, input.ProductId);
    const newQty = existing ? existing.Quantity + input.Quantity : input.Quantity;

    if (product.Stock < newQty) {
      throw new AppError(`Cannot add product to cart. Requested quantity: ${newQty}, Available stock: ${product.Stock}`, 400);
    }

    if (existing) {
      return cartRepository.updateItem(existing.CartItemId, newQty);
    }

    return cartRepository.addItem(userId, input.ProductId, input.Quantity);
  }

  async updateItem(userId: number, cartItemId: number, input: UpdateCartItemInput) {
    const item = await cartRepository.findById(cartItemId);
    if (!item || item.UserId !== userId) {
      throw new AppError('Cart item not found.', 404);
    }

    if (item.Product.Stock < input.Quantity) {
      throw new AppError(`Cannot update cart. Requested quantity: ${input.Quantity}, Available stock: ${item.Product.Stock}`, 400);
    }

    return cartRepository.updateItem(cartItemId, input.Quantity);
  }

  async removeItem(userId: number, cartItemId: number) {
    const item = await cartRepository.findById(cartItemId);
    if (!item || item.UserId !== userId) {
      throw new AppError('Cart item not found.', 404);
    }

    return cartRepository.removeItem(cartItemId);
  }
}
export default CartService;
