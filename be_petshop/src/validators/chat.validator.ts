import { z } from 'zod';

export const createMessageSchema = z.object({
  conversationId: z.number().int().optional(),
  ChatRoomId: z.number().int().optional(),
  message: z.string().min(1, 'Message content cannot be empty').optional(),
  Content: z.string().min(1, 'Message content cannot be empty').optional(),
});

export type CreateMessageInput = z.infer<typeof createMessageSchema>;
