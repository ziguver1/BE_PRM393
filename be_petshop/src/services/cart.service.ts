import { CartRepository } from '../repositories/cart.repository';
import { ProductRepository } from '../repositories/product.repository';
import { AddCartItemInput, UpdateCartItemInput } from '../validators/cart.validator';
import { AppError } from '../middleware/error.middleware';

const cartRepository = new CartRepository();
const productRepository = new ProductRepository();

// Helper to get variant price and stock
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

export class CartService {
  async getCart(userId: number) {
    const items = await cartRepository.findByUserId(userId);
    const mappedItems = items.map((item: any) => {
      const { price, stock } = getVariantDetails(item.Product, item.SelectedVariant);
      return {
        ...item,
        Product: {
          ...item.Product,
          Price: price,
          Stock: stock,
        }
      };
    });

    const total = mappedItems.reduce((sum: number, item: any) => sum + item.Quantity * item.Product.Price, 0);

    return {
      items: mappedItems,
      total: Number(total.toFixed(2)),
    };
  }

  async addItem(userId: number, input: AddCartItemInput) {
    const product = await productRepository.findById(input.ProductId);
    if (!product) {
      throw new AppError('Product not found.', 404);
    }

    const selectedVariant = input.SelectedVariant || "";
    const { price, stock } = getVariantDetails(product, selectedVariant);

    const existing = await cartRepository.findItemByUserAndProduct(userId, input.ProductId, selectedVariant);
    const newQty = existing ? existing.Quantity + input.Quantity : input.Quantity;

    if (stock < newQty) {
      throw new AppError(`Cannot add product to cart. Requested quantity: ${newQty}, Available stock: ${stock}`, 400);
    }

    if (existing) {
      return cartRepository.updateItem(existing.CartItemId, newQty);
    }

    return cartRepository.addItem(userId, input.ProductId, input.Quantity, selectedVariant);
  }

  async updateItem(userId: number, cartItemId: number, input: UpdateCartItemInput) {
    const item = await cartRepository.findById(cartItemId);
    if (!item || item.UserId !== userId) {
      throw new AppError('Cart item not found.', 404);
    }

    const { price, stock } = getVariantDetails(item.Product, item.SelectedVariant);

    if (stock < input.Quantity) {
      throw new AppError(`Cannot update cart. Requested quantity: ${input.Quantity}, Available stock: ${stock}`, 400);
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
