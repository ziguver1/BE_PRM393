import { NextRequest, NextResponse } from 'next/server';
import { CategoryService } from '../../services/category.service';
import { createCategorySchema, updateCategorySchema } from '../../validators/category.validator';
import { handleError, AppError } from '../../middleware/error.middleware';

const categoryService = new CategoryService();

export class CategoriesController {
  async getAll() {
    try {
      const categories = await categoryService.getAll();
      return NextResponse.json(categories, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async getById(req: NextRequest, context: { params: { id: string } }) {
    try {
      const id = Number(context.params.id);
      if (isNaN(id)) {
        throw new AppError('Invalid category ID format.', 400);
      }
      const category = await categoryService.getById(id);
      return NextResponse.json(category, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async create(req: NextRequest) {
    try {
      const body = await req.json();
      const validated = createCategorySchema.parse(body);
      const newCategory = await categoryService.create(validated);
      return NextResponse.json(newCategory, { status: 201 });
    } catch (error) {
      return handleError(error);
    }
  }

  async update(req: NextRequest, context: { params: { id: string } }) {
    try {
      const id = Number(context.params.id);
      if (isNaN(id)) {
        throw new AppError('Invalid category ID format.', 400);
      }
      const body = await req.json();
      const validated = updateCategorySchema.parse(body);
      const updatedCategory = await categoryService.update(id, validated);
      return NextResponse.json(updatedCategory, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async delete(req: NextRequest, context: { params: { id: string } }) {
    try {
      const id = Number(context.params.id);
      if (isNaN(id)) {
        throw new AppError('Invalid category ID format.', 400);
      }
      await categoryService.delete(id);
      return NextResponse.json(
        { message: 'Category deleted successfully.' },
        { status: 200 }
      );
    } catch (error) {
      return handleError(error);
    }
  }
}
export default CategoriesController;
