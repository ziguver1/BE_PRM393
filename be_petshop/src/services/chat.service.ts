import { ChatRepository } from '../repositories/chat.repository';
import { AppError } from '../middleware/error.middleware';

const chatRepository = new ChatRepository();

export class ChatService {
  async getRooms(userId: number, role: string) {
    if (role === 'ADMIN') {
      return chatRepository.findAllConversations();
    }
    const conversation = await chatRepository.findOrCreateConversation(userId);
    return [conversation]; // Return as array for compatibility
  }

  async getConversation(userId: number, role: string) {
    if (role === 'ADMIN') {
      return chatRepository.findAllConversations();
    }
    return chatRepository.findOrCreateConversation(userId);
  }

  async getMessages(userId: number, role: string, conversationId: number) {
    const conversation = await chatRepository.findConversationById(conversationId);
    if (!conversation) {
      throw new AppError('Cuộc trò chuyện không tồn tại.', 404);
    }

    if (role !== 'ADMIN' && conversation.userId !== userId) {
      throw new AppError('Bạn không có quyền truy cập cuộc trò chuyện này.', 403);
    }

    // Load messages
    const messages = await chatRepository.findMessagesByConversation(conversationId);

    // Clear unread counts and mark messages as read for the active viewer
    if (role === 'ADMIN') {
      await chatRepository.clearUnreadCount(conversationId, 'Admin');
      await chatRepository.markMessagesAsRead(conversationId, 'Admin');
    } else {
      await chatRepository.clearUnreadCount(conversationId, 'Customer');
      await chatRepository.markMessagesAsRead(conversationId, 'Customer');
    }

    return messages;
  }

  async sendMessage(userId: number, role: string, conversationId: number | undefined, content: string) {
    let resolvedId: number;

    if (!conversationId) {
      if (role === 'ADMIN') {
        throw new AppError('Admin phải chỉ định conversationId để gửi tin nhắn.', 400);
      }
      const conversation = await chatRepository.findOrCreateConversation(userId);
      resolvedId = conversation.id;
    } else {
      const conversation = await chatRepository.findConversationById(conversationId);
      if (!conversation) {
        throw new AppError('Cuộc trò chuyện không tồn tại.', 404);
      }
      if (role !== 'ADMIN' && conversation.userId !== userId) {
        throw new AppError('Bạn không có quyền truy cập cuộc trò chuyện này.', 403);
      }
      resolvedId = conversationId;
    }

    const senderType = role === 'ADMIN' ? 'Admin' : 'Customer';
    const message = await chatRepository.createMessage(resolvedId, senderType, userId, content);

    // Trigger local socket notification via secret internal API
    try {
      await fetch('http://localhost:3002/internal/emit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          secret: 'super_secret_internal_pass_2026',
          event: 'new_message',
          room: `conversation_${resolvedId}`,
          data: message,
        }),
      });
    } catch (e) {
      console.warn('Socket server local trigger ignored (not running or offline).');
    }

    return message;
  }
}
export default ChatService;
