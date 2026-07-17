import { apiClient } from '@/api/axios';
import { API_ENDPOINTS } from '@/constants';
import {
  ApiResponse,
  User,
  UpdateUserRole,
  UpdateUserStatus,
  UserFilters,
  PaginatedResponse,
} from '@/types';

export const userService = {
  async getUsers(
    filters?: UserFilters,
    pagination?: { page: number; limit: number }
  ): Promise<PaginatedResponse<User>> {
    const params = new URLSearchParams();
    
    if (filters?.status) params.append('status', filters.status);
    if (filters?.role) params.append('role', filters.role);
    if (filters?.search) params.append('search', filters.search);
    if (pagination?.page) params.append('page', pagination.page.toString());
    if (pagination?.limit) params.append('limit', pagination.limit.toString());

    const response = await apiClient.get<ApiResponse<PaginatedResponse<User>>>(
      `${API_ENDPOINTS.USERS.LIST}?${params.toString()}`
    );
    return response.data.data;
  },

  async getUser(id: string): Promise<User> {
    const response = await apiClient.get<ApiResponse<User>>(
      API_ENDPOINTS.USERS.DETAIL.replace(':id', id)
    );
    return response.data.data;
  },

  async updateUserRole(id: string, data: UpdateUserRole): Promise<User> {
    const response = await apiClient.patch<ApiResponse<User>>(
      API_ENDPOINTS.USERS.UPDATE_ROLE.replace(':id', id),
      data
    );
    return response.data.data;
  },

  async updateUserStatus(id: string, data: UpdateUserStatus): Promise<User> {
    const response = await apiClient.patch<ApiResponse<User>>(
      API_ENDPOINTS.USERS.UPDATE_STATUS.replace(':id', id),
      data
    );
    return response.data.data;
  },
};
