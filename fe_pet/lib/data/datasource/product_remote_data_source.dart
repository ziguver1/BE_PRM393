// ignore_for_file: use_null_aware_elements
import '../models/product_model.dart';
import '../models/paginated_products_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

abstract class ProductRemoteDataSource {
  Future<PaginatedProductsModel> getProducts({
    int page = 1,
    int limit = 10,
    String? search,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
  });

  Future<PaginatedProductsModel> searchProducts({
    int page = 1,
    int limit = 10,
    String? search,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
  });

  Future<ProductModel> getProductById(int id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient _apiClient;

  ProductRemoteDataSourceImpl(this._apiClient);

  Map<String, dynamic> _buildQueryParams({
    required int page,
    required int limit,
    String? search,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
  }) {
    return {
      'page': page,
      'limit': limit,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (categoryId != null) 'categoryId': categoryId,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };
  }

  @override
  Future<PaginatedProductsModel> getProducts({
    int page = 1,
    int limit = 10,
    String? search,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
  }) async {
    final queryParams = _buildQueryParams(
      page: page,
      limit: limit,
      search: search,
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

    final response = await _apiClient.dio.get(
      ApiConstants.products,
      queryParameters: queryParams,
    );
    return PaginatedProductsModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PaginatedProductsModel> searchProducts({
    int page = 1,
    int limit = 10,
    String? search,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
  }) async {
    final queryParams = _buildQueryParams(
      page: page,
      limit: limit,
      search: search,
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

    final response = await _apiClient.dio.get(
      ApiConstants.searchProducts,
      queryParameters: queryParams,
    );
    return PaginatedProductsModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    final response = await _apiClient.dio.get('${ApiConstants.products}/$id');
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }
}
