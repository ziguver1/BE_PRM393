import { z } from 'zod';

export const createNotificationSchema = z.object({
  UserId: z.number().int('User ID must be an integer'),
  Title: z.string().min(1, 'Title is required'),
  Content: z.string().min(1, 'Content is required'),
});

export type CreateNotificationInput = z.infer<typeof createNotificationSchema>;
