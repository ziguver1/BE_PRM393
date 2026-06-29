import prisma from '../lib/prisma';

export class ChatRepository {
  async findRoomsByUser(userId: number) {
    return prisma.chatRoom.findMany({
      where: { UserId: userId },
      orderBy: { CreatedAt: 'desc' },
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
          orderBy: { CreatedAt: 'desc' },
        },
      },
    });
  }

  async findAllRooms() {
    return prisma.chatRoom.findMany({
      orderBy: { CreatedAt: 'desc' },
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
          orderBy: { CreatedAt: 'desc' },
        },
      },
    });
  }

  async findRoomById(chatRoomId: number) {
    return prisma.chatRoom.findUnique({
      where: { ChatRoomId: chatRoomId },
      include: {
        User: true,
      },
    });
  }

  async findOrCreateRoom(userId: number) {
    const existing = await prisma.chatRoom.findFirst({
      where: { UserId: userId },
    });

    if (existing) {
      return existing;
    }

    return prisma.chatRoom.create({
      data: {
        UserId: userId,
      },
    });
  }

  async createMessage(chatRoomId: number, senderId: number, content: string) {
    return prisma.message.create({
      data: {
        ChatRoomId: chatRoomId,
        SenderId: senderId,
        Content: content,
      },
      include: {
        Sender: {
          select: {
            UserId: true,
            FullName: true,
            Avatar: true,
            Role: true,
          },
        },
      },
    });
  }

  async findMessagesByRoom(chatRoomId: number) {
    return prisma.message.findMany({
      where: { ChatRoomId: chatRoomId },
      orderBy: { CreatedAt: 'asc' },
      include: {
        Sender: {
          select: {
            UserId: true,
            FullName: true,
            Avatar: true,
            Role: true,
          },
        },
      },
    });
  }
}
