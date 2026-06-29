import { NotificationsController } from '@/modules/notifications/notifications.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new NotificationsController();

/**
 * @openapi
 * /api/notifications/{id}/read:
 *   put:
 *     summary: Mark a notification as read
 *     tags:
 *       - Notifications
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Notification updated successfully.
 *       401:
 *         description: Unauthorized.
 *       403:
 *         description: Forbidden (Not the owner of the notification).
 *       404:
 *         description: Notification not found.
 */
export const PUT = withAuth((req, context) => controller.markAsRead(req, context));
