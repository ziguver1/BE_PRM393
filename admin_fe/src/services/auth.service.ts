import { apiClient } from '@/api/axios';
import { API_ENDPOINTS } from '@/constants';
import {
  LoginCredentials,
  AuthResponse,
  AdminInfo,
} from '@/types';

export const authService = {
  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    const response = await apiClient.post<AuthResponse>(
      API_ENDPOINTS.AUTH.LOGIN,
      credentials
    );
    return response.data;
  },

  async logout(): Promise<void> {
    try {
      await apiClient.post(API_ENDPOINTS.AUTH.LOGOUT);
    } catch (error) {
      // Ignore logout errors
    }
  },

  async refreshToken(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }> {
    const response = await apiClient.post(API_ENDPOINTS.AUTH.REFRESH, {
      RefreshToken: refreshToken,
    });
    return response.data;
  },

  getCurrentAdmin(): AdminInfo | null {
    const adminInfo = localStorage.getItem('admin_info');
    return adminInfo ? JSON.parse(adminInfo) : null;
  },
};
