import '../entities/product.dart';
import '../../data/models/paginated_products_model.dart';

abstract class ProductRepository {
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

  Future<Product> getProductById(int id);
}
