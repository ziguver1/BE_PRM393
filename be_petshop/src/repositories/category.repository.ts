import prisma from '../lib/prisma';

export class CategoryRepository {
  async findAll() {
    return prisma.category.findMany();
  }

  async findById(categoryId: number) {
    return prisma.category.findUnique({
      where: { CategoryId: categoryId },
    });
  }

  async create(data: any) {
    return prisma.category.create({
      data,
    });
  }

  async update(categoryId: number, data: any) {
    return prisma.category.update({
      where: { CategoryId: categoryId },
      data,
    });
  }

  async delete(categoryId: number) {
    return prisma.category.delete({
      where: { CategoryId: categoryId },
    });
  }
}
