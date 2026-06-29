import { NotificationRepository } from '../repositories/notification.repository';
import { CreateNotificationInput } from '../validators/notification.validator';
import { AppError } from '../middleware/error.middleware';

const notificationRepository = new NotificationRepository();

export class NotificationService {
  async getAllForUser(userId: number) {
    return notificationRepository.findByUserId(userId);
  }

  async create(input: CreateNotificationInput) {
    return notificationRepository.create(input.UserId, input.Title, input.Content);
  }

  async markAsRead(userId: number, notificationId: number) {
    const notif = await notificationRepository.findById(notificationId);
    if (!notif) {
      throw new AppError('Notification not found.', 404);
    }
    if (notif.UserId !== userId) {
      throw new AppError('Forbidden: Access denied to this notification.', 403);
    }
    return notificationRepository.markAsRead(notificationId);
  }
}
export default NotificationService;
