// API Response Types
export interface ApiResponse<T> {
  data: T;
  message?: string;
  success: boolean;
}

export interface ApiError {
  message: string;
  statusCode?: number;
  errors?: Record<string, string[]>;
}

// Auth Types
export interface LoginCredentials {
  Email: string;
  Password: string;
}

export interface AuthResponse {
  user: {
    UserId: number;
    FullName: string;
    Email: string;
    Phone?: string;
    Avatar?: string;
    Role: string;
  };
  accessToken: string;
  refreshToken: string;
}

export interface AdminInfo {
  id: number;
  email: string;
  name: string;
  role: string;
  avatar?: string;
}

// Category Model
export interface Category {
  CategoryId: number;
  Name: string;
  Description: string | null;
  ImageUrl: string | null;
}

// Product Variant Model
export interface ProductVariant {
  ProductVariantId: number;
  ProductId: number;
  Name: string | null;
  Price: number;
  Stock: number;
  Unit: string | null;
  Attributes: any;
}

// Product Model
export interface Product {
  ProductId: number;
  CategoryId: number;
  Name: string;
  Description: string | null;
  Price: number;
  Stock: number;
  ImageUrl: string | null;
  CreatedAt: string;
  UpdatedAt: string;
  Category?: Category;
  ProductVariants?: ProductVariant[];
}

export interface CreateProduct {
  CategoryId: number;
  Name: string;
  Description?: string | null;
  Price: number;
  Stock: number;
  ImageUrl?: string | null;
}

export interface UpdateProduct extends Partial<CreateProduct> {}

// Order Details Model
export interface OrderDetail {
  OrderDetailId: number;
  OrderId: number;
  ProductId: number;
  SelectedVariant: string;
  Quantity: number;
  UnitPrice: number;
  Product?: Product;
}

// Order Model
export interface Order {
  OrderId: number;
  OrderCode: number | null;
  UserId: number;
  TotalAmount: number;
  ShippingAddress: string;
  Status: 'PENDING' | 'PAID' | 'PROCESSING' | 'SHIPPING' | 'DELIVERED' | 'RECEIVED' | 'CANCELLED';
  UserLat: number | null;
  UserLng: number | null;
  RoutePoints: any | null;
  ShippingStartedAt: string | null;
  CreatedAt: string;
  User?: {
    UserId: number;
    FullName: string;
    Email: string;
    Phone?: string;
  };
  OrderDetails?: OrderDetail[];
}

export interface UpdateOrderStatus {
  Status: Order['Status'];
}

// User Types (Keeping for backward compatibility or placeholder, but backend does not support)
export interface User {
  UserId: number;
  FullName: string;
  Email: string;
  Phone: string | null;
  Avatar: string | null;
  Role: 'ADMIN' | 'CUSTOMER';
  CreatedAt: string;
  UpdatedAt: string;
}

export interface UpdateUserRole {
  role: User['Role'];
}

export interface UpdateUserStatus {
  status: string;
}

// Chat Message Model
export interface Message {
  MessageId: number;
  ChatRoomId: number;
  SenderId: number;
  Content: string;
  CreatedAt: string;
  Sender?: {
    UserId: number;
    FullName: string;
    Avatar: string | null;
    Role: string;
  };
}

// Chat Room Model
export interface ChatRoom {
  ChatRoomId: number;
  UserId: number;
  CreatedAt: string;
  User?: {
    UserId: number;
    FullName: string;
    Avatar: string | null;
  };
  Messages?: Message[];
}

export interface SendMessage {
  ChatRoomId: number;
  Content: string;
}

// Dashboard Types
export interface DashboardStats {
  revenue: number;
  orders: number;
  products: number;
  users: number;
  revenueChange: number;
  ordersChange: number;
  productsChange: number;
  usersChange: number;
}

export interface RevenueData {
  date: string;
  revenue: number;
}

export interface OrderData {
  date: string;
  orders: number;
}

export interface TopProduct {
  id: string;
  name: string;
  sold: number;
  revenue: number;
}

// Filter Types
export interface OrderFilters {
  status?: Order['Status'];
  paymentStatus?: string;
  startDate?: string;
  endDate?: string;
  search?: string;
}

export interface UserFilters {
  status?: string;
  role?: User['Role'];
  search?: string;
}

export interface ProductFilters {
  status?: string;
  category?: string;
  search?: string;
}

// Pagination Types
export interface PaginationParams {
  page: number;
  limit: number;
}

export interface PaginatedResponse<T> {
  items?: T[];
  data?: T[];
  total: number;
  page: number;
  limit?: number;
  totalPages: number;
}
