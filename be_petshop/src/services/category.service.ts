import { CategoryRepository } from '../repositories/category.repository';
import { CreateCategoryInput, UpdateCategoryInput } from '../validators/category.validator';
import { AppError } from '../middleware/error.middleware';

const categoryRepository = new CategoryRepository();

export class CategoryService {
  async getAll() {
    return categoryRepository.findAll();
  }

  async getById(id: number) {
    const category = await categoryRepository.findById(id);
    if (!category) {
      throw new AppError('Category not found.', 404);
    }
    return category;
  }

  async create(input: CreateCategoryInput) {
    return categoryRepository.create({
      Name: input.Name,
      Description: input.Description,
      ImageUrl: input.ImageUrl,
    });
  }

  async update(id: number, input: UpdateCategoryInput) {
    await this.getById(id); // Throws if not found
    return categoryRepository.update(id, {
      Name: input.Name,
      Description: input.Description,
      ImageUrl: input.ImageUrl,
    });
  }

  async delete(id: number) {
    await this.getById(id); // Throws if not found
    return categoryRepository.delete(id);
  }
}
export default CategoryService;
