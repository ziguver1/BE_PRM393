import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../data/models/product_model.dart';
import '../domain/entities/product.dart';

class WishlistService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      return {};
    }
    return {'Authorization': 'Bearer $token'};
  }

  // Get user's wishlist
  Future<List<Product>> getWishlist() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _apiClient.dio.get(
        '/wishlist',
        options: Options(headers: headers),
      );
      if (response.statusCode == 200) {
        final list = response.data as List;
        return list.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      throw Exception('Không thể tải danh sách yêu thích');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? e.error ?? 'Lỗi khi tải danh sách yêu thích');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // Add to wishlist
  Future<void> addToWishlist(int productId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _apiClient.dio.post(
        '/wishlist/$productId',
        options: Options(headers: headers),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Lỗi phản hồi từ máy chủ: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? e.error ?? 'Lỗi khi thêm vào danh sách yêu thích');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  // Remove from wishlist
  Future<void> removeFromWishlist(int productId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _apiClient.dio.delete(
        '/wishlist/$productId',
        options: Options(headers: headers),
      );
      if (response.statusCode != 200) {
        throw Exception('Lỗi phản hồi từ máy chủ: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['error'] ?? e.error ?? 'Lỗi khi xóa khỏi danh sách yêu thích');
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }
}
