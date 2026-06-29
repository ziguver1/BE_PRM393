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
      return NextResponse.json(rooms, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async getMessages(req: NextRequest, context: { user: TokenPayload; params: { roomId: string } }) {
    try {
      const userId = context.user.userId;
      const role = context.user.role;
      const roomId = Number(context.params.roomId);
      if (isNaN(roomId)) {
        throw new AppError('Invalid room ID format.', 400);
      }
      const messages = await chatService.getMessages(userId, role, roomId);
      return NextResponse.json(messages, { status: 200 });
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
      const message = await chatService.sendMessage(userId, role, validated);
      return NextResponse.json(message, { status: 201 });
    } catch (error) {
      return handleError(error);
    }
  }
}
export default ChatController;
