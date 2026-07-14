import { z } from 'zod';

export type OrderStatus = 'PENDING' | 'PAID' | 'PROCESSING' | 'SHIPPING' | 'DELIVERED' | 'CANCELLED';

export const createOrderSchema = z.object({
  ShippingAddress: z.string().min(5, 'Shipping address must be at least 5 characters'),
  selectedCartItemIds: z.array(z.number()).optional(),
});

export const updateOrderStatusSchema = z.object({
  Status: z.enum(['PENDING', 'PAID', 'PROCESSING', 'SHIPPING', 'DELIVERED', 'CANCELLED']),
});

export type CreateOrderInput = z.infer<typeof createOrderSchema>;
export type UpdateOrderStatusInput = z.infer<typeof updateOrderStatusSchema>;
