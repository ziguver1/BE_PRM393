import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import fs from 'fs';
import path from 'path';
import { NotificationRepository } from '../repositories/notification.repository';
import { CreateNotificationInput } from '../validators/notification.validator';
import { AppError } from '../middleware/error.middleware';
import prisma from '../lib/prisma';
const notificationRepository = new NotificationRepository();

let isFirebaseInitialized = false;

try {
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const projectId = process.env.VITE_FIREBASE_PROJECT_ID || 'hcm202-2d75e';
  
  const serviceAccountPath = path.join(process.cwd(), 'firebase-service-account.json');

  if (getApps().length > 0) {
    isFirebaseInitialized = true;
    console.log('DEBUG: Firebase Admin already initialized.');
  } else if (privateKey && clientEmail) {
    initializeApp({
      credential: cert({
        projectId,
        clientEmail,
        privateKey: privateKey.replace(/\\n/g, '\n'),
      }),
    });
    isFirebaseInitialized = true;
    console.log('DEBUG: Firebase Admin successfully initialized using credentials from environment.');
  } else if (fs.existsSync(serviceAccountPath)) {
    initializeApp({
      credential: cert(serviceAccountPath),
    });
    isFirebaseInitialized = true;
    console.log('DEBUG: Firebase Admin successfully initialized using firebase-service-account.json.');
  } else {
    console.warn('WARNING: No Firebase Admin credentials found (neither FIREBASE_PRIVATE_KEY/FIREBASE_CLIENT_EMAIL env nor firebase-service-account.json). FCM notifications will be logged/mocked.');
  }
} catch (error) {
  console.error('ERROR: Failed to initialize Firebase Admin:', error);
}

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

  async sendOrderNotification(
    userId: number,
    orderId: number,
    type: 'ORDER_SHIPPING_STARTED' | 'ORDER_DELIVERED',
    title: string,
    body: string
  ) {
    const sentTime = new Date();
    
    // 1. Kiểm tra chống gửi trùng (Idempotency check)
    const existingLog = await prisma.notificationLog.findUnique({
      where: {
        OrderId_Type: {
          OrderId: orderId,
          Type: type,
        },
      },
    });

    if (existingLog) {
      console.log(`DEBUG: Notification type ${type} for Order #${orderId} already sent. Skipping to prevent duplicates.`);
      return;
    }

    // 2. Lấy thông tin user và token
    const user = await prisma.user.findUnique({
      where: { UserId: userId },
      select: { fcmToken: true },
    });

    if (!user) {
      console.warn(`WARNING: User #${userId} not found. Cannot send notification.`);
      return;
    }

    // Lưu in-app notification vào DB trước
    await prisma.notification.create({
      data: {
        UserId: userId,
        Title: title,
        Content: body,
      },
    });

    const fcmToken = user.fcmToken;
    if (!fcmToken) {
      const msg = `No FCM token registered for User #${userId}.`;
      console.warn(`WARNING: ${msg} Skipping FCM push.`);
      // Lưu log trạng thái SKIPPED/FAILED
      await prisma.notificationLog.create({
        data: {
          OrderId: orderId,
          UserId: userId,
          Type: type,
          Status: 'FAILED',
          FailureReason: msg,
          SentAt: sentTime,
        },
      });
      return;
    }

    // 3. Gửi notification qua FCM
    let success = false;
    let failureReason: string | null = null;

    if (isFirebaseInitialized) {
      try {
        await getMessaging().send({
          token: fcmToken,
          notification: {
            title,
            body,
          },
          data: {
            type,
            orderId: orderId.toString(),
          },
        });
        success = true;
      } catch (error: any) {
        failureReason = error.message || error.toString();
        console.error(`ERROR: FCM Send failed: ${failureReason}`);
      }
    } else {
      // Mock mode
      console.log(`MOCK FCM SEND SUCCESS to token [${fcmToken}]: Title: "${title}", Body: "${body}", Data: ${JSON.stringify({ type, orderId })}`);
      success = true;
    }

    // 4. Ghi log kết quả
    await prisma.notificationLog.create({
      data: {
        OrderId: orderId,
        UserId: userId,
        Type: type,
        Status: success ? 'SUCCESS' : 'FAILED',
        FailureReason: failureReason,
        SentAt: sentTime,
      },
    });

    console.log(`LOG: Notification Sent - OrderId: ${orderId}, UserId: ${userId}, Type: ${type}, Status: ${success ? 'SUCCESS' : 'FAILED'}, FailureReason: ${failureReason || 'None'}`);
  }
}
export default NotificationService;
