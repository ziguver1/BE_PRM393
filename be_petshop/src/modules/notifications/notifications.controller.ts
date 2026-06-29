import { NextRequest, NextResponse } from 'next/server';
import { NotificationService } from '../../services/notification.service';
import { createNotificationSchema } from '../../validators/notification.validator';
import { handleError, AppError } from '../../middleware/error.middleware';
import { TokenPayload } from '../../lib/jwt';

const notificationService = new NotificationService();

export class NotificationsController {
  async getAll(req: NextRequest, context: { user: TokenPayload }) {
    try {
      const userId = context.user.userId;
      const notifications = await notificationService.getAllForUser(userId);
      return NextResponse.json(notifications, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async create(req: NextRequest) {
    try {
      const body = await req.json();
      const validated = createNotificationSchema.parse(body);
      const notif = await notificationService.create(validated);
      return NextResponse.json(notif, { status: 201 });
    } catch (error) {
      return handleError(error);
    }
  }

  async markAsRead(req: NextRequest, context: { user: TokenPayload; params: { id: string } }) {
    try {
      const userId = context.user.userId;
      const notificationId = Number(context.params.id);
      if (isNaN(notificationId)) {
        throw new AppError('Invalid notification ID format.', 400);
      }
      const updated = await notificationService.markAsRead(userId, notificationId);
      return NextResponse.json(updated, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }
}
export default NotificationsController;
