const http = require('http');
const express = require('express');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
const { initializeApp, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
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
const serviceAccountPath = path.join(__dirname, '..', 'firebase-service-account.json');
if (fs.existsSync(serviceAccountPath)) {
  try {
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    initializeApp({
      credential: cert(serviceAccount)
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
        await getMessaging().send(messagePayload);
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
  const userId = socket.user.userId;
  const role = socket.user.role;
  console.log(`Socket connected: ${socket.id}, User ID: ${userId}, Role: ${role}`);

  // 1. Connection Delivery Markers: Update pending messages
  const now = new Date();
  if (role === 'ADMIN') {
    // Admin came online: Mark all pending Customer messages as DELIVERED
    (async () => {
      try {
        const sentMessages = await prisma.message.findMany({
          where: { senderType: 'Customer', status: 'SENT', deliveredAt: null },
          select: { conversationId: true }
        });
        if (sentMessages.length > 0) {
          await prisma.message.updateMany({
            where: { senderType: 'Customer', status: 'SENT', deliveredAt: null },
            data: { status: 'DELIVERED', deliveredAt: now }
          });
          const convIds = [...new Set(sentMessages.map(m => m.conversationId))];
          for (const cId of convIds) {
            chatNamespace.to(`conversation_${cId}`).emit('message_delivered', {
              conversationId: cId,
              senderType: 'Customer',
              deliveredAt: now
            });
            chatNamespace.emit('conversations_updated', { conversationId: cId });
          }
        }
      } catch (err) {
        console.error('Error updating deliveries on admin connect:', err);
      }
    })();
  } else {
    // Customer came online: Mark all pending Admin messages in their conversation as DELIVERED
    (async () => {
      try {
        const conv = await prisma.conversation.findUnique({
          where: { userId }
        });
        if (conv) {
          const sentCount = await prisma.message.count({
            where: { conversationId: conv.id, senderType: 'Admin', status: 'SENT', deliveredAt: null }
          });
          if (sentCount > 0) {
            await prisma.message.updateMany({
              where: { conversationId: conv.id, senderType: 'Admin', status: 'SENT', deliveredAt: null },
              data: { status: 'DELIVERED', deliveredAt: now }
            });
            chatNamespace.to(`conversation_${conv.id}`).emit('message_delivered', {
              conversationId: conv.id,
              senderType: 'Admin',
              deliveredAt: now
            });
            chatNamespace.emit('conversations_updated', { conversationId: conv.id });
          }
        }
      } catch (err) {
        console.error('Error updating deliveries on customer connect:', err);
      }
    })();
  }

  // 2. Room join (Subscribe to Room - DOES NOT mark as read)
  socket.on('join', async (conversationId) => {
    try {
      const convId = Number(conversationId);
      if (isNaN(convId)) return;

      // Customer can only join their own conversation
      if (role !== 'ADMIN') {
        const conv = await prisma.conversation.findUnique({
          where: { id: convId }
        });
        if (!conv || conv.userId !== userId) {
          console.warn(`Unauthorized join from user ${userId} for room ${convId}`);
          return;
        }
      }

      const roomName = `conversation_${convId}`;
      socket.join(roomName);
      console.log(`User ${userId} successfully joined room: ${roomName}`);
    } catch (e) {
      console.error('Error during room join setup:', e);
    }
  });

  // 2b. Explicit conversation opened trigger -> Read receipts
  socket.on('conversation_opened', async (data) => {
    try {
      const { conversationId } = data;
      const convId = Number(conversationId);
      if (isNaN(convId)) return;

      if (role !== 'ADMIN') {
        const conv = await prisma.conversation.findUnique({
          where: { id: convId }
        });
        if (!conv || conv.userId !== userId) return;
      }

      const roomName = `conversation_${convId}`;
      const nowTime = new Date();

      if (role === 'ADMIN') {
        await prisma.conversation.update({
          where: { id: convId },
          data: { unreadAdmin: 0 }
        });
        await prisma.message.updateMany({
          where: { conversationId: convId, senderType: 'Customer', readAt: null },
          data: { isRead: true, status: 'READ', readAt: nowTime }
        });
        // Notify customer that Admin read their messages
        chatNamespace.to(roomName).emit('message_read', { conversationId: convId, senderType: 'Customer', readAt: nowTime });
        // Notify admin panel list that count is cleared
        chatNamespace.emit('conversations_updated', { conversationId: convId, unreadAdmin: 0 });
      } else {
        await prisma.conversation.update({
          where: { id: convId },
          data: { unreadCustomer: 0 }
        });
        await prisma.message.updateMany({
          where: { conversationId: convId, senderType: 'Admin', readAt: null },
          data: { isRead: true, status: 'READ', readAt: nowTime }
        });
        // Notify admin that Customer read their messages
        chatNamespace.to(roomName).emit('message_read', { conversationId: convId, senderType: 'Admin', readAt: nowTime });
        // Notify list
        chatNamespace.emit('conversations_updated', { conversationId: convId, unreadCustomer: 0 });
      }
      console.log(`conversation_opened: User ${userId} (${role}) marked messages as READ in room ${convId}`);
    } catch (err) {
      console.error('Error in conversation_opened handler:', err);
    }
  });

  // 2c. Message delivery acknowledgement from client
  socket.on('message_delivered_ack', async (data) => {
    try {
      const { messageId } = data;
      const msgId = Number(messageId);
      if (isNaN(msgId)) return;

      const message = await prisma.message.findUnique({
        where: { id: msgId }
      });
      if (!message || message.deliveredAt) return; // Already delivered or doesn't exist

      const nowTime = new Date();
      const updatedMsg = await prisma.message.update({
        where: { id: msgId },
        data: {
          deliveredAt: nowTime,
          status: message.status === 'READ' ? 'READ' : 'DELIVERED'
        }
      });

      const roomName = `conversation_${message.conversationId}`;
      chatNamespace.to(roomName).emit('message_delivered', {
        messageId: msgId,
        conversationId: message.conversationId,
        senderType: message.senderType,
        deliveredAt: nowTime
      });

      chatNamespace.emit('conversations_updated', { conversationId: message.conversationId });
      console.log(`Acknowledged delivery for message ID: ${msgId}`);
    } catch (err) {
      console.error('Error in message_delivered_ack:', err);
    }
  });

  // 3. Customer Send Message
  socket.on('customer_send_message', async (data) => {
    try {
      const { conversationId, message, clientTempId } = data;
      const convId = Number(conversationId);
      if (!message || isNaN(convId)) return;

      const conv = await prisma.conversation.findUnique({
        where: { id: convId }
      });
      if (!conv || conv.userId !== userId) return;

      // Determine initial status based on recipient state
      const roomName = `conversation_${convId}`;
      const socketsInRoom = await chatNamespace.in(roomName).fetchSockets();
      const isAdminInRoom = socketsInRoom.some(s => s.user && s.user.role === 'ADMIN');

      let status = 'SENT';
      let isRead = false;
      let readAt = null;
      let deliveredAt = null;

      if (isAdminInRoom) {
        status = 'READ';
        isRead = true;
        readAt = new Date();
        deliveredAt = new Date();
      } else {
        const allSockets = Array.from(chatNamespace.sockets.values());
        const isAdminOnline = allSockets.some(s => s.user && s.user.role === 'ADMIN');
        if (isAdminOnline) {
          status = 'DELIVERED';
          deliveredAt = new Date();
        }
      }

      const msg = await prisma.message.create({
        data: {
          conversationId: convId,
          senderType: 'Customer',
          senderId: userId,
          message: message,
          status: status,
          isRead: isRead,
          deliveredAt: deliveredAt,
          readAt: readAt
        }
      });

      const updateData = {
        lastMessage: message,
        lastMessageAt: new Date(),
      };
      if (status !== 'READ') {
        updateData.unreadAdmin = { increment: 1 };
      }

      const updatedConv = await prisma.conversation.update({
        where: { id: convId },
        data: updateData
      });

      const responseData = {
        MessageId: msg.id,
        ChatRoomId: msg.conversationId,
        SenderId: msg.senderId,
        Content: msg.message,
        CreatedAt: msg.createdAt,
        senderType: msg.senderType,
        isRead: msg.isRead,
        status: msg.status,
        sentAt: msg.sentAt,
        deliveredAt: msg.deliveredAt,
        readAt: msg.readAt,
        clientTempId: clientTempId
      };

      chatNamespace.to(roomName).emit('new_message', responseData);
      
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

  // 4. Admin Send Message
  socket.on('admin_send_message', async (data) => {
    try {
      const { conversationId, message, clientTempId } = data;
      const convId = Number(conversationId);
      if (!message || isNaN(convId) || role !== 'ADMIN') return;

      const conv = await prisma.conversation.findUnique({
        where: { id: convId }
      });
      if (!conv) return;

      const roomName = `conversation_${convId}`;
      const socketsInRoom = await chatNamespace.in(roomName).fetchSockets();
      const isCustomerInRoom = socketsInRoom.some(
        s => s.user && s.user.role !== 'ADMIN' && s.user.userId === conv.userId
      );

      let status = 'SENT';
      let isRead = false;
      let readAt = null;
      let deliveredAt = null;

      if (isCustomerInRoom) {
        status = 'READ';
        isRead = true;
        readAt = new Date();
        deliveredAt = new Date();
      } else {
        const allSockets = Array.from(chatNamespace.sockets.values());
        const isCustomerOnline = allSockets.some(
          s => s.user && s.user.role !== 'ADMIN' && s.user.userId === conv.userId
        );
        if (isCustomerOnline) {
          status = 'DELIVERED';
          deliveredAt = new Date();
        }
      }

      const msg = await prisma.message.create({
        data: {
          conversationId: convId,
          senderType: 'Admin',
          senderId: userId,
          message: message,
          status: status,
          isRead: isRead,
          deliveredAt: deliveredAt,
          readAt: readAt
        }
      });

      const updateData = {
        lastMessage: message,
        lastMessageAt: new Date(),
      };
      if (status !== 'READ') {
        updateData.unreadCustomer = { increment: 1 };
      }

      const updatedConv = await prisma.conversation.update({
        where: { id: convId },
        data: updateData
      });

      const responseData = {
        MessageId: msg.id,
        ChatRoomId: msg.conversationId,
        SenderId: msg.senderId,
        Content: msg.message,
        CreatedAt: msg.createdAt,
        senderType: msg.senderType,
        isRead: msg.isRead,
        status: msg.status,
        sentAt: msg.sentAt,
        deliveredAt: msg.deliveredAt,
        readAt: msg.readAt,
        clientTempId: clientTempId
      };

      chatNamespace.to(roomName).emit('new_message', responseData);

      chatNamespace.emit('conversations_updated', {
        conversationId: convId,
        unreadCustomer: updatedConv.unreadCustomer,
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
    status: data.readAt ? 'READ' : (data.deliveredAt ? 'DELIVERED' : 'SENT'),
    sentAt: data.sentAt || data.createdAt,
    deliveredAt: data.deliveredAt,
    readAt: data.readAt
  };

  chatNamespace.to(room).emit(event, responseData);

  res.status(200).json({ success: true });
});

const PORT = 3002;
server.listen(PORT, () => {
  console.log(`Standalone Realtime Support Chat Socket.IO server running on port ${PORT}`);
});
