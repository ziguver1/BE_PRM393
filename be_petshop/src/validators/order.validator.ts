import { z } from 'zod';

export type OrderStatus = 'PENDING' | 'PAID' | 'PROCESSING' | 'SHIPPING' | 'DELIVERED' | 'RECEIVED' | 'CANCELLED';

export const createOrderSchema = z.object({
  shippingLatitude: z.number({ required_error: 'shippingLatitude is required' }),
  shippingLongitude: z.number({ required_error: 'shippingLongitude is required' }),
  selectedCartItemIds: z.array(z.number()).optional(),
});

export const updateOrderStatusSchema = z.object({
  Status: z.enum(['PENDING', 'PAID', 'PROCESSING', 'SHIPPING', 'DELIVERED', 'RECEIVED', 'CANCELLED']),
});

export type CreateOrderInput = z.infer<typeof createOrderSchema>;
export type UpdateOrderStatusInput = z.infer<typeof updateOrderStatusSchema>;
