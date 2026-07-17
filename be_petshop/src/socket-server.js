const http = require('http');
const express = require('express');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const prisma = new PrismaClient();
const app = express();
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

const JWT_ACCESS_SECRET = process.env.JWT_ACCESS_SECRET || "petshop_jwt_access_secret_key_2026_secure";

// 1. Initialize Firebase Admin
const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');
if (fs.existsSync(serviceAccountPath)) {
  try {
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin initialized on socket server.');
  } catch (e) {
    console.error('Failed to initialize Firebase Admin on socket server:', e);
  }
} else {
  console.warn('Firebase Service Account JSON not found on socket server.');
}

// Helper to send FCM push if user is offline
async function sendPushIfOffline(conversationId, customerUserId, messageText) {
  try {
    const roomName = `conversation_${conversationId}`;
    const socketsInRoom = await chatNamespace.in(roomName).fetchSockets();
    const hasCustomerOnline = socketsInRoom.some(s => s.user && s.user.userId === customerUserId);

    if (!hasCustomerOnline) {
      console.log(`Customer ${customerUserId} is offline in conversation ${conversationId}. Sending FCM.`);
      const user = await prisma.user.findUnique({
        where: { UserId: customerUserId }
      });
      if (user && user.fcmToken) {
        const messagePayload = {
          notification: {
            title: 'Pet Shop Support',
            body: messageText || 'Bạn có một tin nhắn mới từ bộ phận hỗ trợ.'
          },
          token: user.fcmToken,
        };
        await admin.messaging().send(messagePayload);
        console.log('FCM message sent successfully to customer token.');
      } else {
        console.log('No FCM token found for customer', customerUserId);
      }
    } else {
      console.log(`Customer ${customerUserId} is online. Skipping FCM.`);
    }
  } catch (err) {
    console.error('Error in sendPushIfOffline:', err);
  }
}

// 2. Chat Namespace & Middleware Auth
const chatNamespace = io.of('/chat');

chatNamespace.use((socket, next) => {
  const token = socket.handshake.auth?.token || socket.handshake.query?.token;
  if (!token) {
    return next(new Error('Authentication error: Token is required'));
  }
  try {
    const decoded = jwt.verify(token, JWT_ACCESS_SECRET);
    socket.user = {
      userId: decoded.userId,
      role: decoded.role,
      email: decoded.email
    };
    next();
  } catch (err) {
    console.error('Socket JWT Auth Error:', err.message);
    return next(new Error('Authentication error: Invalid token'));
  }
});

chatNamespace.on('connection', (socket) => {
  console.log(`Socket connected: ${socket.id}, User ID: ${socket.user.userId}, Role: ${socket.user.role}`);

  socket.on('join', async (conversationId) => {
    try {
      const convId = Number(conversationId);
      if (isNaN(convId)) return;

      // Customer can only join their own conversation
      if (socket.user.role !== 'ADMIN') {
        const conv = await prisma.conversation.findUnique({
          where: { id: convId }
        });
        if (!conv || conv.userId !== socket.user.userId) {
          console.warn(`Unauthorized join from user ${socket.user.userId} for room ${convId}`);
          return;
        }
      }

      const roomName = `conversation_${convId}`;
      socket.join(roomName);
      console.log(`User ${socket.user.userId} successfully joined room: ${roomName}`);

      // Clear unread badge for reader
      if (socket.user.role === 'ADMIN') {
        await prisma.conversation.update({
          where: { id: convId },
          data: { unreadAdmin: 0 }
        });
        await prisma.message.updateMany({
          where: { conversationId: convId, senderType: 'Customer', isRead: false },
          data: { isRead: true }
        });
        // Notify admin panel list that count is cleared
        chatNamespace.emit('conversations_updated', { conversationId: convId, unreadAdmin: 0 });
      } else {
        await prisma.conversation.update({
          where: { id: convId },
          data: { unreadCustomer: 0 }
        });
        await prisma.message.updateMany({
          where: { conversationId: convId, senderType: 'Admin', isRead: false },
          data: { isRead: true }
        });
      }
    } catch (e) {
      console.error('Error during room join setup:', e);
    }
  });

  socket.on('customer_send_message', async (data) => {
    try {
      const { conversationId, message } = data;
      const convId = Number(conversationId);
      if (!message || isNaN(convId)) return;

      const conv = await prisma.conversation.findUnique({
        where: { id: convId }
      });
      if (!conv || conv.userId !== socket.user.userId) return;

      const msg = await prisma.message.create({
        data: {
          conversationId: convId,
          senderType: 'Customer',
          senderId: socket.user.userId,
          message: message,
        }
      });

      const updatedConv = await prisma.conversation.update({
        where: { id: convId },
        data: {
          lastMessage: message,
          lastMessageAt: new Date(),
          unreadAdmin: { increment: 1 }
        }
      });

      const responseData = {
        MessageId: msg.id,
        ChatRoomId: msg.conversationId,
        SenderId: msg.senderId,
        Content: msg.message,
        CreatedAt: msg.createdAt,
        senderType: msg.senderType,
        isRead: msg.isRead,
      };

      chatNamespace.to(`conversation_${convId}`).emit('new_message', responseData);
      
      // Notify all admins of updated unread badge in list
      chatNamespace.emit('conversations_updated', {
        conversationId: convId,
        unreadAdmin: updatedConv.unreadAdmin,
        lastMessage: message,
        lastMessageAt: updatedConv.lastMessageAt,
      });

    } catch (e) {
      console.error('Error in customer_send_message handler:', e);
    }
  });

  socket.on('admin_send_message', async (data) => {
    try {
      const { conversationId, message } = data;
      const convId = Number(conversationId);
      if (!message || isNaN(convId) || socket.user.role !== 'ADMIN') return;

      const conv = await prisma.conversation.findUnique({
        where: { id: convId }
      });
      if (!conv) return;

      const msg = await prisma.message.create({
        data: {
          conversationId: convId,
          senderType: 'Admin',
          senderId: socket.user.userId,
          message: message,
        }
      });

      const updatedConv = await prisma.conversation.update({
        where: { id: convId },
        data: {
          lastMessage: message,
          lastMessageAt: new Date(),
          unreadCustomer: { increment: 1 }
        }
      });

      const responseData = {
        MessageId: msg.id,
        ChatRoomId: msg.conversationId,
        SenderId: msg.senderId,
        Content: msg.message,
        CreatedAt: msg.createdAt,
        senderType: msg.senderType,
        isRead: msg.isRead,
      };

      chatNamespace.to(`conversation_${convId}`).emit('new_message', responseData);

      chatNamespace.emit('conversations_updated', {
        conversationId: convId,
        unreadAdmin: 0,
        lastMessage: message,
        lastMessageAt: updatedConv.lastMessageAt,
      });

      // Send Firebase Cloud Message if user is offline
      await sendPushIfOffline(convId, conv.userId, message);

    } catch (e) {
      console.error('Error in admin_send_message handler:', e);
    }
  });

  socket.on('disconnect', () => {
    console.log(`Socket disconnected: ${socket.id}`);
  });
});

// 3. Secret trigger endpoint for REST API fallbacks
app.post('/internal/emit', async (req, res) => {
  const { secret, event, room, data } = req.body;
  if (secret !== 'super_secret_internal_pass_2026') {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const responseData = {
    MessageId: data.id,
    ChatRoomId: data.conversationId,
    SenderId: data.senderId,
    Content: data.message,
    CreatedAt: data.createdAt,
    senderType: data.senderType,
    isRead: data.isRead,
  };

  chatNamespace.to(room).emit(event, responseData);

  res.status(200).json({ success: true });
});

const PORT = 3002;
server.listen(PORT, () => {
  console.log(`Standalone Realtime Support Chat Socket.IO server running on port ${PORT}`);
});
