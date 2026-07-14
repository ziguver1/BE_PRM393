import prisma from '../lib/prisma';
import { ProductQueryInput } from '../validators/product.validator';

/**
 * Interface for get products query parameters
 */
export interface GetProductParams {
  page: number;
  limit: number;
  search?: string;
  categoryId?: number;
  filterOptionIds?: number[];
}

/**
 * Interface for pagination response
 */
export interface GetProductsResponse {
  data: any[];
  total: number;
  page: number;
  totalPages: number;
}

export class ProductRepository {
  /**
   * Get products with support for filtering, searching, and pagination
   * Supports faceted search with multiple filter options
   */
  async getProducts(params: GetProductParams): Promise<GetProductsResponse> {
    const { page, limit, search, categoryId, filterOptionIds } = params;
    const skip = (page - 1) * limit;

    // Build WHERE condition
    const where: any = {};

    // Filter by category if provided
    if (categoryId) {
      where.CategoryId = categoryId;
    }

    // Search by product name (case insensitive)
    if (search) {
      where.Name = {
        contains: search,
        mode: 'insensitive',
      };
    }

    // Apply faceted search filters
    // All selected filter options must be present (AND logic)
    if (filterOptionIds && filterOptionIds.length > 0) {
      where.AND = filterOptionIds.map((filterId) => ({
        ProductFilters: {
          some: {
            FilterOptionId: filterId,
          },
        },
      }));
    }

    // Execute query in parallel
    const [data, total] = await Promise.all([
      prisma.product.findMany({
        where,
        skip,
        take: limit,
        include: {
          Category: true,
          Images: true,
          ProductVariants: true,
          ProductFilters: {
            include: {
              FilterOption: {
                include: {
                  Group: true,
                },
              },
            },
          },
        },
      }),
      prisma.product.count({ where }),
    ]);

    const totalPages = Math.ceil(total / limit);

    return {
      data,
      total,
      page,
      totalPages,
    };
  }

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
        Images: true,
        ProductVariants: true,
        ProductFilters: {
          include: {
            FilterOption: {
              include: {
                Group: true,
              },
            },
          },
        },
      },
    });
  }

  async create(data: any) {
    // Support nested creation of structured variants (ProductVariant model)
    const { Variants, ProductVariants, ...rest } = data;
    const createData: any = { ...rest };

    // keep JSON variants if provided (legacy / frontend can use this)
    if (Variants !== undefined) createData.Variants = Variants;

    // structured variants to create in separate table
    const variantsToCreate = ProductVariants || Variants;
    if (variantsToCreate && Array.isArray(variantsToCreate) && variantsToCreate.length > 0) {
      createData.ProductVariants = {
        create: variantsToCreate.map((v: any) => ({
          Name: v.Name,
          Price: v.Price,
          Stock: v.Stock,
          Unit: v.Unit,
          Attributes: v.Attributes,
        })),
      };
    }

    return prisma.product.create({
      data: createData,
      include: { Category: true, ProductVariants: true },
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
