import { z } from 'zod';

export const createMessageSchema = z.object({
  ChatRoomId: z.number().int('ChatRoomId must be an integer').optional(),
  Content: z.string().min(1, 'Message content cannot be empty'),
});

export type CreateMessageInput = z.infer<typeof createMessageSchema>;
