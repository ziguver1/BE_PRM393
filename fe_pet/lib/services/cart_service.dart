import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../data/models/cart_model.dart';

class CartService {
  final ApiClient _apiClient = ApiClient();

  // Fetch current shopping cart
  Future<CartResponse> getCart() async {
    try {
      final response = await _apiClient.dio.get('/cart');
      if (response.statusCode == 200) {
        return CartResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Không thể tải thông tin giỏ hàng');
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Lỗi khi tải giỏ hàng');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // Add a product to the cart
  Future<CartItem> addToCart(int productId, int quantity) async {
    try {
      final response = await _apiClient.dio.post(
        '/cart/items',
        data: {
          'ProductId': productId,
          'Quantity': quantity,
        },
      );
      if (response.statusCode == 201) {
        return CartItem.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Không thể thêm sản phẩm vào giỏ hàng');
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Lỗi khi thêm sản phẩm');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // Update item quantity in the cart
  Future<CartItem> updateCartItem(int cartItemId, int quantity) async {
    try {
      final response = await _apiClient.dio.put(
        '/cart/items/$cartItemId',
        data: {
          'Quantity': quantity,
        },
      );
      if (response.statusCode == 200) {
        return CartItem.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Không thể cập nhật số lượng sản phẩm');
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Lỗi khi cập nhật số lượng');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // Delete an item from the cart
  Future<void> removeCartItem(int cartItemId) async {
    try {
      final response = await _apiClient.dio.delete('/cart/items/$cartItemId');
      if (response.statusCode != 200) {
        throw Exception('Không thể xóa sản phẩm khỏi giỏ hàng');
      }
    } on DioException catch (e) {
      throw Exception(e.error ?? 'Lỗi khi xóa sản phẩm');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }
}
