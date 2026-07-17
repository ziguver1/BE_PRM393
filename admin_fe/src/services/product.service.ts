import { apiClient } from '@/api/axios';
import { API_ENDPOINTS } from '@/constants';
import {
  Product,
  CreateProduct,
  UpdateProduct,
  ProductFilters,
  PaginatedResponse,
} from '@/types';

export const productService = {
  async getProducts(
    filters?: ProductFilters,
    pagination?: { page: number; limit: number }
  ): Promise<PaginatedResponse<Product>> {
    const params = new URLSearchParams();
    
    // category filter corresponds to categoryId on backend
    if (filters?.category) params.append('categoryId', filters.category);
    if (filters?.search) params.append('search', filters.search);
    if (pagination?.page) params.append('page', pagination.page.toString());
    if (pagination?.limit) params.append('limit', pagination.limit.toString());

    const response = await apiClient.get<PaginatedResponse<Product>>(
      `${API_ENDPOINTS.PRODUCTS.LIST}?${params.toString()}`
    );
    return response.data;
  },

  async getProduct(id: string): Promise<Product> {
    const response = await apiClient.get<Product>(
      API_ENDPOINTS.PRODUCTS.DETAIL.replace(':id', id)
    );
    return response.data;
  },

  async createProduct(data: CreateProduct): Promise<Product> {
    const response = await apiClient.post<Product>(
      API_ENDPOINTS.PRODUCTS.CREATE,
      data
    );
    return response.data;
  },

  async updateProduct(id: string, data: UpdateProduct): Promise<Product> {
    // Backend update uses PUT method instead of PATCH
    const response = await apiClient.put<Product>(
      API_ENDPOINTS.PRODUCTS.UPDATE.replace(':id', id),
      data
    );
    return response.data;
  },

  async deleteProduct(id: string): Promise<void> {
    await apiClient.delete(API_ENDPOINTS.PRODUCTS.DELETE.replace(':id', id));
  },
};
