import prisma from '../lib/prisma';

export class NotificationRepository {
  async findByUserId(userId: number) {
    return prisma.notification.findMany({
      where: { UserId: userId },
      orderBy: { CreatedAt: 'desc' },
    });
  }

  async findById(notificationId: number) {
    return prisma.notification.findUnique({
      where: { NotificationId: notificationId },
    });
  }

  async create(userId: number, title: string, content: string) {
    return prisma.notification.create({
      data: {
        UserId: userId,
        Title: title,
        Content: content,
        IsRead: false,
      },
    });
  }

  async markAsRead(notificationId: number) {
    return prisma.notification.update({
      where: { NotificationId: notificationId },
      data: { IsRead: true },
    });
  }
}
