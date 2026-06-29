import { ProductRepository } from '../repositories/product.repository';
import { CategoryRepository } from '../repositories/category.repository';
import { CreateProductInput, UpdateProductInput, ProductQueryInput } from '../validators/product.validator';
import { AppError } from '../middleware/error.middleware';

const productRepository = new ProductRepository();
const categoryRepository = new CategoryRepository();

export class ProductService {
  async getAll(params: ProductQueryInput) {
    return productRepository.findAll(params);
  }

  async getById(id: number) {
    const product = await productRepository.findById(id);
    if (!product) {
      throw new AppError('Product not found.', 404);
    }
    return product;
  }

  async create(input: CreateProductInput) {
    const category = await categoryRepository.findById(input.CategoryId);
    if (!category) {
      throw new AppError('Invalid CategoryId: Category does not exist.', 400);
    }

    return productRepository.create({
      CategoryId: input.CategoryId,
      Name: input.Name,
      Description: input.Description,
      Price: input.Price,
      Stock: input.Stock,
      ImageUrl: input.ImageUrl,
    });
  }

  async update(id: number, input: UpdateProductInput) {
    await this.getById(id); // Throws if not found

    if (input.CategoryId !== undefined) {
      const category = await categoryRepository.findById(input.CategoryId);
      if (!category) {
        throw new AppError('Invalid CategoryId: Category does not exist.', 400);
      }
    }

    return productRepository.update(id, {
      CategoryId: input.CategoryId,
      Name: input.Name,
      Description: input.Description,
      Price: input.Price,
      Stock: input.Stock,
      ImageUrl: input.ImageUrl,
    });
  }

  async delete(id: number) {
    await this.getById(id); // Throws if not found
    return productRepository.delete(id);
  }
}
export default ProductService;
