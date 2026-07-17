import { apiClient } from '@/api/axios';
import { API_ENDPOINTS } from '@/constants';
import {
  Order,
  UpdateOrderStatus,
  OrderFilters,
} from '@/types';

export const orderService = {
  async getOrders(
    filters?: OrderFilters,
    pagination?: { page: number; limit: number }
  ): Promise<Order[]> {
    const params = new URLSearchParams();
    
    // Backend doesn't support query parameters for order listing, 
    // but we can append them to keep it clean.
    if (filters?.status) params.append('status', filters.status);
    if (filters?.paymentStatus) params.append('paymentStatus', filters.paymentStatus);
    if (filters?.startDate) params.append('startDate', filters.startDate);
    if (filters?.endDate) params.append('endDate', filters.endDate);
    if (filters?.search) params.append('search', filters.search);
    if (pagination?.page) params.append('page', pagination.page.toString());
    if (pagination?.limit) params.append('limit', pagination.limit.toString());

    const response = await apiClient.get<Order[]>(
      `${API_ENDPOINTS.ORDERS.LIST}?${params.toString()}`
    );
    return response.data;
  },

  async getOrder(id: string): Promise<Order> {
    const response = await apiClient.get<Order>(
      API_ENDPOINTS.ORDERS.DETAIL.replace(':id', id)
    );
    return response.data;
  },

  async updateOrderStatus(id: string, data: UpdateOrderStatus): Promise<Order> {
    // Backend uses PUT method for status update: PUT /api/orders/[id]/status
    const response = await apiClient.put<Order>(
      API_ENDPOINTS.ORDERS.UPDATE_STATUS.replace(':id', id),
      data
    );
    return response.data;
  },
};
