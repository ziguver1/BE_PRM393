import { ProductRepository } from '../repositories/product.repository';
import { CategoryRepository } from '../repositories/category.repository';
import { CreateProductInput, UpdateProductInput, ProductQueryInput } from '../validators/product.validator';
import { AppError } from '../middleware/error.middleware';

const productRepository = new ProductRepository();
const categoryRepository = new CategoryRepository();

export class ProductService {
  /**
   * Get all products with filtering, searching, and pagination
   * Supports faceted search using filter options
   */
  async getAllProducts(query: any) {
    try {
      // Parse and validate pagination parameters
      const page = Math.max(1, parseInt(query.page || '1', 10));
      const limit = Math.max(1, parseInt(query.limit || '10', 10));

      // Parse category ID if provided
      const categoryId = query.categoryId
        ? parseInt(query.categoryId, 10)
        : undefined;

      if (categoryId && isNaN(categoryId)) {
        throw new AppError('Invalid categoryId parameter', 400);
      }

      // Parse filter option IDs from comma-separated string
      // Example: "1,5,8" -> [1, 5, 8]
      let filterOptionIds: number[] | undefined;
      if (query.filters) {
        try {
          filterOptionIds = query.filters
            .split(',')
            .map((id: string) => parseInt(id.trim(), 10))
            .filter((id: number) => !isNaN(id));

          if (filterOptionIds.length === 0) {
            filterOptionIds = undefined;
          }
        } catch (error) {
          throw new AppError('Invalid filters parameter format', 400);
        }
      }

      // Build normalized parameters object
      const params = {
        page,
        limit,
        ...(query.search && { search: query.search }),
        ...(categoryId && { categoryId }),
        ...(filterOptionIds && { filterOptionIds }),
      };

      // Call repository to fetch products
      const result = await productRepository.getProducts(params);

      return result;
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      throw new AppError('Error fetching products', 500);
    }
  }

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

    // Allow passing structured variants (`Variants`) from the request.
    return productRepository.create({
      CategoryId: input.CategoryId,
      Name: input.Name,
      Description: input.Description,
      Price: input.Price,
      Stock: input.Stock,
      ImageUrl: input.ImageUrl,
      Unit: (input as any).Unit,
      Variants: (input as any).Variants,
      ProductVariants: (input as any).Variants,
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
