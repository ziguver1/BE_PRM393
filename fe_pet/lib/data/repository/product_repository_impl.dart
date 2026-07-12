import '../../domain/entities/product.dart';
import '../../domain/repository/product_repository.dart';
import '../datasource/product_remote_data_source.dart';
import '../models/paginated_products_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl(this._remoteDataSource);

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
  }) {
    return _remoteDataSource.getProducts(
      page: page,
      limit: limit,
      search: search,
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
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
  }) {
    return _remoteDataSource.searchProducts(
      page: page,
      limit: limit,
      search: search,
      categoryId: categoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  @override
  Future<Product> getProductById(int id) {
    return _remoteDataSource.getProductById(id);
  }
}
