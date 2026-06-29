import prisma from '../lib/prisma';
import { ProductQueryInput } from '../validators/product.validator';

export class ProductRepository {
  async findAll(params: ProductQueryInput) {
    const { page, limit, search, categoryId, minPrice, maxPrice, sortBy, sortOrder } = params;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (search) {
      where.Name = {
        contains: search,
      };
    }

    if (categoryId) {
      where.CategoryId = categoryId;
    }

    if (minPrice !== undefined || maxPrice !== undefined) {
      const priceFilter: any = {};
      if (minPrice !== undefined) priceFilter.gte = minPrice;
      if (maxPrice !== undefined) priceFilter.lte = maxPrice;
      where.Price = priceFilter;
    }

    const orderBy: any = {};
    if (sortBy === 'price') {
      orderBy.Price = sortOrder;
    } else if (sortBy === 'name') {
      orderBy.Name = sortOrder;
    } else {
      orderBy.CreatedAt = sortOrder;
    }

    const [items, total] = await Promise.all([
      prisma.product.findMany({
        where,
        orderBy,
        skip,
        take: limit,
        include: {
          Category: true,
        },
      }),
      prisma.product.count({ where }),
    ]);

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findById(productId: number) {
    return prisma.product.findUnique({
      where: { ProductId: productId },
      include: {
        Category: true,
      },
    });
  }

  async create(data: any) {
    return prisma.product.create({
      data,
    });
  }

  async update(productId: number, data: any) {
    return prisma.product.update({
      where: { ProductId: productId },
      data,
    });
  }

  async delete(productId: number) {
    return prisma.product.delete({
      where: { ProductId: productId },
    });
  }
}
