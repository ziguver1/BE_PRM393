import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../data/models/product_model.dart';
import '../data/models/paginated_products_model.dart';

class ProductService {
  final Dio _dio = ApiClient().dio;

  /// Fetch products with filtering, searching, and pagination support
  /// 
  /// Parameters:
  /// - [page]: Page number (default: 1)
  /// - [limit]: Items per page (default: 10)
  /// - [categoryId]: Filter by category ID
  /// - [filters]: Comma-separated filter option IDs (e.g., "1,5,8")
  /// - [search]: Search query string
  /// 
  /// Returns: [PaginatedProductsModel] with product list and pagination info
  Future<PaginatedProductsModel> fetchProducts({
    int page = 1,
    int limit = 10,
    int? categoryId,
    String? filters,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (categoryId != null) 'categoryId': categoryId,
        if (filters != null && filters.isNotEmpty) 'filters': filters,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      debugPrint('ProductService: Fetching products with params: $queryParams');

      final response = await _dio.get(
        '${ApiConstants.apiBaseUrl}${ApiConstants.products}',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final paginatedData = PaginatedProductsModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        debugPrint('ProductService: Fetched ${paginatedData.data.length} products');
        return paginatedData;
      }

      throw Exception('Failed to fetch products: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('ProductService DioException: ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      debugPrint('ProductService Error: $e');
      throw Exception('Error fetching products: $e');
    }
  }

  /// Fetch a single product by ID
  Future<ProductModel> fetchProductById(int productId) async {
    try {
      debugPrint('ProductService: Fetching product ID: $productId');

      final response = await _dio.get(
        '${ApiConstants.apiBaseUrl}${ApiConstants.products}/$productId',
      );

      if (response.statusCode == 200) {
        return ProductModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw Exception('Failed to fetch product: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('ProductService DioException: ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      debugPrint('ProductService Error: $e');
      throw Exception('Error fetching product: $e');
    }
  }

  /// Search products
  Future<PaginatedProductsModel> searchProducts({
    String? query,
    int? categoryId,
    String? filters,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (query != null && query.isNotEmpty) 'search': query,
        if (categoryId != null) 'categoryId': categoryId,
        if (filters != null && filters.isNotEmpty) 'filters': filters,
      };

      debugPrint('ProductService: Searching products with params: $queryParams');

      final response = await _dio.get(
        '${ApiConstants.apiBaseUrl}${ApiConstants.searchProducts}',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return PaginatedProductsModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw Exception('Search failed: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('ProductService DioException: ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      debugPrint('ProductService Error: $e');
      throw Exception('Error searching products: $e');
    }
  }

  /// Apply filters to products
  Future<PaginatedProductsModel> applyFilters({
    required String filterString,
    int? categoryId,
    int page = 1,
    int limit = 10,
  }) async {
    return fetchProducts(
      page: page,
      limit: limit,
      categoryId: categoryId,
      filters: filterString,
    );
  }

  /// Handle DioException and return user-friendly error message
  String _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Hết thời gian kết nối. Vui lòng kiểm tra mạng.';
      case DioExceptionType.sendTimeout:
        return 'Hết thời gian gửi dữ liệu. Vui lòng thử lại.';
      case DioExceptionType.receiveTimeout:
        return 'Hết thời gian chờ phản hồi. Vui lòng thử lại.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        switch (statusCode) {
          case 400:
            return 'Yêu cầu không hợp lệ. Vui lòng kiểm tra lại.';
          case 401:
            return 'Phiên đã hết hạn. Vui lòng đăng nhập lại.';
          case 403:
            return 'Bạn không có quyền truy cập.';
          case 404:
            return 'Không tìm thấy sản phẩm.';
          case 500:
            return 'Lỗi máy chủ. Vui lòng thử lại sau.';
          default:
            return 'Lỗi: $statusCode. Vui lòng thử lại.';
        }
      case DioExceptionType.cancel:
        return 'Yêu cầu đã bị hủy.';
      default:
        return 'Lỗi kết nối. Vui lòng kiểm tra mạng.';
    }
  }
}
