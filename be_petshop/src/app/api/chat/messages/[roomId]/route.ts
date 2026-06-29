import { ChatController } from '@/modules/chat/chat.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new ChatController();

/**
 * @openapi
 * /api/chat/messages/{roomId}:
 *   get:
 *     summary: Retrieve message history for a chat room
 *     tags:
 *       - Chat
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: roomId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: List of messages inside the room.
 *       401:
 *         description: Unauthorized.
 *       403:
 *         description: Forbidden (Not the user's room).
 *       404:
 *         description: Chat room not found.
 */
export const GET = withAuth((req, context) => controller.getMessages(req, context));
