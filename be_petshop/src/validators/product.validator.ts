import { z } from 'zod';

export const createProductSchema = z.object({
  CategoryId: z.number().int('Category ID must be an integer'),
  Name: z.string().min(2, 'Name must be at least 2 characters'),
  Description: z.string().optional().nullable(),
  Price: z.number().positive('Price must be a positive number'),
  Stock: z.number().int('Stock must be an integer').nonnegative('Stock cannot be negative'),
  ImageUrl: z.string().url('Invalid image URL').optional().nullable(),
});

export const updateProductSchema = createProductSchema.partial();

export const productQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().default(10),
  search: z.string().optional(),
  categoryId: z.coerce.number().int().optional(),
  minPrice: z.coerce.number().positive().optional(),
  maxPrice: z.coerce.number().positive().optional(),
  sortBy: z.enum(['price', 'createdAt', 'name']).default('createdAt'),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),
  filters: z.string().optional(),
});

export type CreateProductInput = z.infer<typeof createProductSchema>;
export type UpdateProductInput = z.infer<typeof updateProductSchema>;
export type ProductQueryInput = z.infer<typeof productQuerySchema>;
