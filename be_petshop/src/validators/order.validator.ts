import { z } from 'zod';

export type OrderStatus = 'PENDING' | 'PROCESSING' | 'SHIPPING' | 'DELIVERED' | 'CANCELLED';

export const createOrderSchema = z.object({
  ShippingAddress: z.string().min(5, 'Shipping address must be at least 5 characters'),
});

export const updateOrderStatusSchema = z.object({
  Status: z.enum(['PENDING', 'PROCESSING', 'SHIPPING', 'DELIVERED', 'CANCELLED']),
});

export type CreateOrderInput = z.infer<typeof createOrderSchema>;
export type UpdateOrderStatusInput = z.infer<typeof updateOrderStatusSchema>;
