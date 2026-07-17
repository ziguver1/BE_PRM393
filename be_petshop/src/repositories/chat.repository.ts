import prisma from '../lib/prisma';

export class ChatRepository {
  async findConversationsByUser(userId: number) {
    return prisma.conversation.findMany({
      where: { userId: userId },
      orderBy: { updatedAt: 'desc' },
      include: {
        User: {
          select: {
            UserId: true,
            FullName: true,
            Avatar: true,
          },
        },
        Messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
        },
      },
    });
  }

  async findAllConversations() {
    return prisma.conversation.findMany({
      orderBy: [
        { unreadAdmin: 'desc' },
        { lastMessageAt: 'desc' },
      ],
      include: {
        User: {
          select: {
            UserId: true,
            FullName: true,
            Avatar: true,
          },
        },
        Messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
        },
      },
    });
  }

  async findConversationById(id: number) {
    return prisma.conversation.findUnique({
      where: { id: id },
      include: {
        User: true,
      },
    });
  }

  async findOrCreateConversation(userId: number) {
    const existing = await prisma.conversation.findUnique({
      where: { userId: userId },
    });

    if (existing) {
      return existing;
    }

    return prisma.conversation.create({
      data: {
        userId: userId,
        lastMessage: 'Cuộc trò chuyện đã được tạo.',
        lastMessageAt: new Date(),
      },
    });
  }

  async createMessage(conversationId: number, senderType: 'Customer' | 'Admin', senderId: number, message: string) {
    // 1. Create message
    const msg = await prisma.message.create({
      data: {
        conversationId: conversationId,
        senderType: senderType,
        senderId: senderId,
        message: message,
      },
    });

    // 2. Update conversation last message & unread badge
    const updateData: any = {
      lastMessage: message,
      lastMessageAt: new Date(),
    };

    if (senderType === 'Customer') {
      updateData.unreadAdmin = { increment: 1 };
    } else {
      updateData.unreadCustomer = { increment: 1 };
    }

    await prisma.conversation.update({
      where: { id: conversationId },
      data: updateData,
    });

    return msg;
  }

  async findMessagesByConversation(conversationId: number) {
    return prisma.message.findMany({
      where: { conversationId: conversationId },
      orderBy: { createdAt: 'asc' },
    });
  }

  async clearUnreadCount(conversationId: number, typeToClear: 'Customer' | 'Admin') {
    const updateData: any = {};
    if (typeToClear === 'Customer') {
      updateData.unreadCustomer = 0;
    } else {
      updateData.unreadAdmin = 0;
    }

    return prisma.conversation.update({
      where: { id: conversationId },
      data: updateData,
    });
  }

  async markMessagesAsRead(conversationId: number, senderTypeToMarkRead: 'Customer' | 'Admin') {
    return prisma.message.updateMany({
      where: {
        conversationId: conversationId,
        senderType: senderTypeToMarkRead === 'Customer' ? 'Admin' : 'Customer', // Mark the *other* party's messages as read
        isRead: false,
      },
      data: {
        isRead: true,
      },
    });
  }
}
