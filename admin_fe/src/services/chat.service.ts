import { apiClient } from '@/api/axios';
import { API_ENDPOINTS } from '@/constants';
import {
  ChatRoom,
  Message,
  SendMessage,
} from '@/types';

export const chatService = {
  async getRooms(): Promise<ChatRoom[]> {
    const response = await apiClient.get<ChatRoom[]>(
      API_ENDPOINTS.CHAT.ROOMS
    );
    return response.data;
  },

  async getMessages(roomId: number): Promise<Message[]> {
    // GET /api/chat/messages/[roomId]
    const response = await apiClient.get<Message[]>(
      `${API_ENDPOINTS.CHAT.MESSAGES}/${roomId}`
    );
    return response.data;
  },

  async sendMessage(data: SendMessage): Promise<Message> {
    const response = await apiClient.post<Message>(
      API_ENDPOINTS.CHAT.MESSAGES,
      data
    );
    return response.data;
  },
};
