import { NotificationsController } from '@/modules/notifications/notifications.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new NotificationsController();

/**
 * @openapi
 * /api/notifications:
 *   get:
 *     summary: Retrieve current user's notifications
 *     tags:
 *       - Notifications
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of notifications.
 *       401:
 *         description: Unauthorized.
 *   post:
 *     summary: Send a notification to a user (Admin only)
 *     tags:
 *       - Notifications
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - UserId
 *               - Title
 *               - Content
 *             properties:
 *               UserId:
 *                 type: integer
 *                 example: 1
 *               Title:
 *                 type: string
 *                 example: Order Shipped!
 *               Content:
 *                 type: string
 *                 example: Your order #12 has been picked up by the courier.
 *     responses:
 *       201:
 *         description: Notification created successfully.
 *       400:
 *         description: Validation error.
 *       401:
 *         description: Unauthorized.
 *       403:
 *         description: Forbidden.
 */
export const GET = withAuth((req, context) => controller.getAll(req, context));
export const POST = withAuth((req, context) => controller.create(req), ['ADMIN']);
