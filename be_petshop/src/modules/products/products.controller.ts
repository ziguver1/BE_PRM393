import { NextRequest, NextResponse } from 'next/server';
import { ProductService } from '../../services/product.service';
import { createProductSchema, updateProductSchema, productQuerySchema } from '../../validators/product.validator';
import { handleError, AppError } from '../../middleware/error.middleware';
import { getOptionalUser } from '../../middleware/auth.middleware';

const productService = new ProductService();

export class ProductsController {
  async getAll(req: NextRequest) {
    try {
      const user = getOptionalUser(req);
      const userId = user?.userId;

      const searchParams = req.nextUrl.searchParams;
      const queryParams = {
        page: searchParams.get('page') || undefined,
        limit: searchParams.get('limit') || undefined,
        search: searchParams.get('search') || undefined,
        categoryId: searchParams.get('categoryId') || undefined,
        minPrice: searchParams.get('minPrice') || undefined,
        maxPrice: searchParams.get('maxPrice') || undefined,
        sortBy: searchParams.get('sortBy') || undefined,
        sortOrder: searchParams.get('sortOrder') || undefined,
        filters: searchParams.get('filters') || undefined,
      };

      const validated = productQuerySchema.parse(queryParams);
      // Use new getAllProducts method if filters are provided, otherwise use getAll
      if (validated.filters) {
        const result = await productService.getAllProducts(queryParams, userId);
        return NextResponse.json(result, { status: 200 });
      } else {
        const result = await productService.getAll(validated, userId);
        return NextResponse.json(result, { status: 200 });
      }
    } catch (error) {
      return handleError(error);
    }
  }

  async getById(req: NextRequest, context: { params: { id: string } }) {
    try {
      const user = getOptionalUser(req);
      const userId = user?.userId;

      const id = Number(context.params.id);
      if (isNaN(id)) {
        throw new AppError('Invalid product ID format.', 400);
      }
      const product = await productService.getById(id, userId);
      return NextResponse.json(product, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async create(req: NextRequest) {
    try {
      const body = await req.json();
      const validated = createProductSchema.parse(body);
      const newProduct = await productService.create(validated);
      return NextResponse.json(newProduct, { status: 201 });
    } catch (error) {
      return handleError(error);
    }
  }

  async update(req: NextRequest, context: { params: { id: string } }) {
    try {
      const id = Number(context.params.id);
      if (isNaN(id)) {
        throw new AppError('Invalid product ID format.', 400);
      }
      const body = await req.json();
      const validated = updateProductSchema.parse(body);
      const updatedProduct = await productService.update(id, validated);
      return NextResponse.json(updatedProduct, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async delete(req: NextRequest, context: { params: { id: string } }) {
    try {
      const id = Number(context.params.id);
      if (isNaN(id)) {
        throw new AppError('Invalid product ID format.', 400);
      }
      await productService.delete(id);
      return NextResponse.json(
        { message: 'Product deleted successfully.' },
        { status: 200 }
      );
    } catch (error) {
      return handleError(error);
    }
  }
}
export default ProductsController;
