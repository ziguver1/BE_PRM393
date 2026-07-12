class ApiConstants {
  static const String baseUrl = 'https://be-prm393-1.onrender.com';
  static const String apiBaseUrl = '$baseUrl/api';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Products
  static const String products = '/products';
  static const String searchProducts = '/products/search';

  // Categories
  static const String categories = '/categories';

  // Cart
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';

  // Orders
  static const String orders = '/orders';

  // Notifications
  static const String notifications = '/notifications';

  // Chat
  static const String chatRooms = '/chat/rooms';
  static const String chatMessages = '/chat/messages';

  // Upload
  static const String upload = '/upload';
}
