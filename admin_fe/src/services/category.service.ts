import { apiClient } from '@/api/axios';
import { API_ENDPOINTS } from '@/constants';
import { Category } from '@/types';

export const categoryService = {
  async getCategories(): Promise<Category[]> {
    const response = await apiClient.get<Category[]>(
      API_ENDPOINTS.CATEGORIES.LIST
    );
    return response.data;
  },
};
