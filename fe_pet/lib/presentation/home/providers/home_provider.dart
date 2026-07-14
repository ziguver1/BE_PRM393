import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../core/configs/providers.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/paginated_products_model.dart';

// Fetch all categories
final homeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategories();
});

// Fetch featured/latest products for Home (limit 10)
// Use datasource directly to get ProductModel with full relations (images, variants, filters)
final homeFeaturedProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final dataSource = ref.watch(productRemoteDataSourceProvider);
  final queryParams = {
    'page': 1,
    'limit': 10,
    'sortBy': 'createdAt',
    'sortOrder': 'desc',
  };
  final response = await dataSource.getProducts(
    page: queryParams['page'] as int,
    limit: queryParams['limit'] as int,
    sortBy: queryParams['sortBy'] as String?,
    sortOrder: queryParams['sortOrder'] as String?,
  );
  return response.data;
});

// Fetch popular products for Home (limit 10)
// Use datasource directly to get ProductModel with full relations (images, variants, filters)
final homePopularProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final dataSource = ref.watch(productRemoteDataSourceProvider);
  final queryParams = {
    'page': 1,
    'limit': 10,
    'sortBy': 'price',
    'sortOrder': 'asc',
  };
  final response = await dataSource.getProducts(
    page: queryParams['page'] as int,
    limit: queryParams['limit'] as int,
    sortBy: queryParams['sortBy'] as String?,
    sortOrder: queryParams['sortOrder'] as String?,
  );
  return response.data;
});

// Fetch full product detail by id (used by router)
final productDetailProvider = FutureProvider.family<ProductModel, int>((ref, productId) async {
  // Use datasource directly to get ProductModel with all relations (images, variants, filters)
  final dataSource = ref.watch(productRemoteDataSourceProvider);
  return dataSource.getProductById(productId);
});
