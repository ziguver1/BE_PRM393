import { ChatController } from '@/modules/chat/chat.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new ChatController();

/**
 * @openapi
 * /api/chat/rooms:
 *   get:
 *     summary: Retrieve chat rooms
 *     description: Customers see their own chat rooms. Admins see all chat rooms active in the system.
 *     tags:
 *       - Chat
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of chat rooms.
 *       401:
 *         description: Unauthorized.
 */
export const GET = withAuth((req, context) => controller.getRooms(req, context));
