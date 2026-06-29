import { ChatController } from '@/modules/chat/chat.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new ChatController();

/**
 * @openapi
 * /api/chat/messages:
 *   post:
 *     summary: Send a chat message
 *     description: Customers can send messages. If ChatRoomId is empty, it finds or creates their single room. Admins must specify ChatRoomId to reply.
 *     tags:
 *       - Chat
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - Content
 *             properties:
 *               ChatRoomId:
 *                 type: integer
 *                 example: 1
 *               Content:
 *                 type: string
 *                 example: Hello, I have a question about my pet order.
 *     responses:
 *       201:
 *         description: Message created successfully.
 *       400:
 *         description: Bad request (e.g. Admin sending message without specifying roomId).
 *       401:
 *         description: Unauthorized.
 *       403:
 *         description: Forbidden (Not the user's room).
 *       404:
 *         description: Chat room not found.
 */
export const POST = withAuth((req, context) => controller.sendMessage(req, context));
