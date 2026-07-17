import { apiClient } from '@/api/axios';
import { API_ENDPOINTS } from '@/constants';
import {
  ApiResponse,
  DashboardStats,
  RevenueData,
  OrderData,
  TopProduct,
} from '@/types';

export const dashboardService = {
  async getStats(): Promise<DashboardStats> {
    const response = await apiClient.get<ApiResponse<DashboardStats>>(
      API_ENDPOINTS.DASHBOARD.STATS
    );
    return response.data.data;
  },

  async getRevenueData(days: number = 30): Promise<RevenueData[]> {
    const response = await apiClient.get<ApiResponse<RevenueData[]>>(
      `${API_ENDPOINTS.DASHBOARD.REVENUE}?days=${days}`
    );
    return response.data.data;
  },

  async getOrderData(days: number = 30): Promise<OrderData[]> {
    const response = await apiClient.get<ApiResponse<OrderData[]>>(
      `${API_ENDPOINTS.DASHBOARD.ORDERS}?days=${days}`
    );
    return response.data.data;
  },

  async getTopProducts(limit: number = 10): Promise<TopProduct[]> {
    const response = await apiClient.get<ApiResponse<TopProduct[]>>(
      `${API_ENDPOINTS.DASHBOARD.TOP_PRODUCTS}?limit=${limit}`
    );
    return response.data.data;
  },
};
