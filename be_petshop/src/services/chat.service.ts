import { ChatRepository } from '../repositories/chat.repository';
import { CreateMessageInput } from '../validators/chat.validator';
import { AppError } from '../middleware/error.middleware';

const chatRepository = new ChatRepository();

export class ChatService {
  async getRooms(userId: number, role: string) {
    if (role === 'ADMIN') {
      return chatRepository.findAllRooms();
    }
    return chatRepository.findRoomsByUser(userId);
  }

  async getMessages(userId: number, role: string, roomId: number) {
    const room = await chatRepository.findRoomById(roomId);
    if (!room) {
      throw new AppError('Chat room not found.', 404);
    }

    if (role !== 'ADMIN' && room.UserId !== userId) {
      throw new AppError('Forbidden: Access denied to this chat room.', 403);
    }

    return chatRepository.findMessagesByRoom(roomId);
  }

  async sendMessage(userId: number, role: string, input: CreateMessageInput) {
    let roomId: number;

    if (!input.ChatRoomId) {
      if (role === 'ADMIN') {
        throw new AppError('Admin must specify a ChatRoomId to send a message.', 400);
      }
      const room = await chatRepository.findOrCreateRoom(userId);
      roomId = room.ChatRoomId;
    } else {
      const room = await chatRepository.findRoomById(input.ChatRoomId);
      if (!room) {
        throw new AppError('Chat room not found.', 404);
      }
      if (role !== 'ADMIN' && room.UserId !== userId) {
        throw new AppError('Forbidden: Access denied to this chat room.', 403);
      }
      roomId = input.ChatRoomId;
    }

    return chatRepository.createMessage(roomId, userId, input.Content);
  }
}
export default ChatService;
