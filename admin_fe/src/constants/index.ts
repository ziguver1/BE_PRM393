// API Endpoints
export const API_ENDPOINTS = {
  AUTH: {
    LOGIN: '/auth/login',
    REFRESH: '/auth/refresh',
    LOGOUT: '/auth/logout',
  },
  ORDERS: {
    LIST: '/orders',
    DETAIL: '/orders/:id',
    UPDATE_STATUS: '/orders/:id/status',
  },
  PRODUCTS: {
    LIST: '/products',
    DETAIL: '/products/:id',
    CREATE: '/products',
    UPDATE: '/products/:id',
    DELETE: '/products/:id',
  },
  CHAT: {
    ROOMS: '/chat/rooms',
    MESSAGES: '/chat/messages',
  },
  CATEGORIES: {
    LIST: '/categories',
  },
  USERS: {
    LIST: '/users',
    DETAIL: '/users/:id',
    UPDATE_ROLE: '/users/:id/role',
    UPDATE_STATUS: '/users/:id/status',
  },
  DASHBOARD: {
    STATS: '/dashboard/stats',
    REVENUE: '/dashboard/revenue',
    ORDERS: '/dashboard/orders',
    TOP_PRODUCTS: '/dashboard/top-products',
  },
} as const;

// Order Status
export const ORDER_STATUS = {
  PENDING: 'PENDING',
  PAID: 'PAID',
  PROCESSING: 'PROCESSING',
  SHIPPING: 'SHIPPING',
  DELIVERED: 'DELIVERED',
  RECEIVED: 'RECEIVED',
  CANCELLED: 'CANCELLED',
} as const;

export const ORDER_STATUS_LABELS: Record<keyof typeof ORDER_STATUS, string> = {
  PENDING: 'Chờ xác nhận',
  PAID: 'Đã thanh toán',
  PROCESSING: 'Đang xử lý',
  SHIPPING: 'Đang giao',
  DELIVERED: 'Đã giao',
  RECEIVED: 'Đã nhận',
  CANCELLED: 'Đã hủy',
};

export const ORDER_STATUS_COLORS: Record<keyof typeof ORDER_STATUS, string> = {
  PENDING: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
  PAID: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
  PROCESSING: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200',
  SHIPPING: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200',
  DELIVERED: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
  RECEIVED: 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900 dark:text-emerald-200',
  CANCELLED: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
};

// Payment Status
export const PAYMENT_STATUS = {
  PENDING: 'PENDING',
  PAID: 'PAID',
  FAILED: 'FAILED',
  REFUNDED: 'REFUNDED',
} as const;

export const PAYMENT_STATUS_LABELS: Record<keyof typeof PAYMENT_STATUS, string> = {
  PENDING: 'Chờ thanh toán',
  PAID: 'Đã thanh toán',
  FAILED: 'Thất bại',
  REFUNDED: 'Đã hoàn tiền',
};

export const PAYMENT_STATUS_COLORS: Record<keyof typeof PAYMENT_STATUS, string> = {
  PENDING: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
  PAID: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
  FAILED: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
  REFUNDED: 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200',
};

// User Status
export const USER_STATUS = {
  ACTIVE: 'ACTIVE',
  INACTIVE: 'INACTIVE',
  BANNED: 'BANNED',
} as const;

export const USER_STATUS_LABELS: Record<keyof typeof USER_STATUS, string> = {
  ACTIVE: 'Hoạt động',
  INACTIVE: 'Không hoạt động',
  BANNED: 'Đã khóa',
};

export const USER_STATUS_COLORS: Record<keyof typeof USER_STATUS, string> = {
  ACTIVE: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
  INACTIVE: 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200',
  BANNED: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
};

// User Role
export const USER_ROLE = {
  CUSTOMER: 'CUSTOMER',
  ADMIN: 'ADMIN',
} as const;

export const USER_ROLE_LABELS: Record<keyof typeof USER_ROLE, string> = {
  CUSTOMER: 'Khách hàng',
  ADMIN: 'Quản trị viên',
};

export const USER_ROLE_COLORS: Record<keyof typeof USER_ROLE, string> = {
  CUSTOMER: 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200',
  ADMIN: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200',
};

// Product Status
export const PRODUCT_STATUS = {
  ACTIVE: 'ACTIVE',
  INACTIVE: 'INACTIVE',
  OUT_OF_STOCK: 'OUT_OF_STOCK',
} as const;

export const PRODUCT_STATUS_LABELS: Record<keyof typeof PRODUCT_STATUS, string> = {
  ACTIVE: 'Hoạt động',
  INACTIVE: 'Không hoạt động',
  OUT_OF_STOCK: 'Hết hàng',
};

export const PRODUCT_STATUS_COLORS: Record<keyof typeof PRODUCT_STATUS, string> = {
  ACTIVE: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
  INACTIVE: 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200',
  OUT_OF_STOCK: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
};

// Pagination
export const DEFAULT_PAGE_SIZE = 10;
export const PAGE_SIZES = [10, 20, 50, 100] as const;

// Storage Keys
export const STORAGE_KEYS = {
  ACCESS_TOKEN: 'admin_access_token',
  REFRESH_TOKEN: 'admin_refresh_token',
  ADMIN_INFO: 'admin_info',
  THEME: 'admin_theme',
} as const;
