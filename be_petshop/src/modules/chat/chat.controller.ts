import { NextRequest, NextResponse } from 'next/server';
import { ChatService } from '../../services/chat.service';
import { createMessageSchema } from '../../validators/chat.validator';
import { handleError, AppError } from '../../middleware/error.middleware';
import { TokenPayload } from '../../lib/jwt';

const chatService = new ChatService();

export class ChatController {
  async getRooms(req: NextRequest, context: { user: TokenPayload }) {
    try {
      const userId = context.user.userId;
      const role = context.user.role;
      const rooms = await chatService.getRooms(userId, role);
      // Format response to look like the old ChatRoom model if the requester is using old fields
      const formatted = rooms.map((r: any) => ({
        ChatRoomId: r.id,
        UserId: r.userId,
        CreatedAt: r.createdAt,
        UpdatedAt: r.updatedAt,
        unreadAdmin: r.unreadAdmin,
        unreadCustomer: r.unreadCustomer,
        User: r.User,
        Messages: r.Messages ? r.Messages.map((m: any) => ({
          MessageId: m.id,
          ChatRoomId: m.conversationId,
          SenderId: m.senderId,
          Content: m.message,
          CreatedAt: m.createdAt,
        })) : [],
      }));
      return NextResponse.json(formatted, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async getConversation(req: NextRequest, context: { user: TokenPayload }) {
    try {
      const userId = context.user.userId;
      const role = context.user.role;
      const conversation = await chatService.getConversation(userId, role);
      return NextResponse.json(conversation, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async getMessages(req: NextRequest, context: any) {
    try {
      const userId = context.user.userId;
      const role = context.user.role;

      // Extract conversationId from searchParams or route dynamic params
      const searchParams = new URL(req.url).searchParams;
      const conversationIdStr = searchParams.get('conversationId') || context.params?.roomId || context.params?.conversationId;
      const conversationId = Number(conversationIdStr);

      if (isNaN(conversationId)) {
        throw new AppError('Mã hội thoại không hợp lệ.', 400);
      }

      const messages = await chatService.getMessages(userId, role, conversationId);
      // Map back to backward-compatible format if required
      const formatted = messages.map((m: any) => ({
        MessageId: m.id,
        ChatRoomId: m.conversationId,
        SenderId: m.senderId,
        Content: m.message,
        CreatedAt: m.createdAt,
        senderType: m.senderType,
        isRead: m.isRead,
        messageType: m.messageType,
      }));
      return NextResponse.json(formatted, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async sendMessage(req: NextRequest, context: { user: TokenPayload }) {
    try {
      const userId = context.user.userId;
      const role = context.user.role;
      const body = await req.json();
      const validated = createMessageSchema.parse(body);

      const content = validated.message || validated.Content;
      const conversationId = validated.conversationId || validated.ChatRoomId;

      if (!content) {
        throw new AppError('Nội dung tin nhắn không thể bỏ trống.', 400);
      }

      const message = await chatService.sendMessage(userId, role, conversationId, content);
      const formatted = {
        MessageId: message.id,
        ChatRoomId: message.conversationId,
        SenderId: message.senderId,
        Content: message.message,
        CreatedAt: message.createdAt,
        senderType: message.senderType,
        isRead: message.isRead,
        messageType: message.messageType,
      };

      return NextResponse.json(formatted, { status: 201 });
    } catch (error) {
      return handleError(error);
    }
  }
}
export default ChatController;
