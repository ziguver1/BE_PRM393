import { z } from 'zod';

export const createCategorySchema = z.object({
  Name: z.string().min(2, 'Name must be at least 2 characters'),
  Description: z.string().optional().nullable(),
  ImageUrl: z.string().url('Invalid image URL').optional().nullable(),
});

export const updateCategorySchema = createCategorySchema.partial();

export type CreateCategoryInput = z.infer<typeof createCategorySchema>;
export type UpdateCategoryInput = z.infer<typeof updateCategorySchema>;
