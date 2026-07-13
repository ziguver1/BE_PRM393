import { z } from 'zod';

export const addCartItemSchema = z.object({
  ProductId: z.number().int('Product ID must be an integer'),
  Quantity: z.number().int('Quantity must be an integer').positive('Quantity must be at least 1'),
  SelectedVariant: z.string().optional(),
});

export const updateCartItemSchema = z.object({
  Quantity: z.number().int('Quantity must be an integer').positive('Quantity must be at least 1'),
});

export type AddCartItemInput = z.infer<typeof addCartItemSchema>;
export type UpdateCartItemInput = z.infer<typeof updateCartItemSchema>;
