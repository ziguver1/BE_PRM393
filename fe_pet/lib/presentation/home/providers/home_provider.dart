import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../../core/configs/providers.dart';

// Fetch all categories
final homeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategories();
});

// Fetch featured/latest products for Home (limit 10)
final homeFeaturedProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final paginated = await repository.getProducts(page: 1, limit: 10, sortBy: 'createdAt', sortOrder: 'desc');
  return paginated.items;
});

// Fetch popular products for Home (limit 10)
final homePopularProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final paginated = await repository.getProducts(page: 1, limit: 10, sortBy: 'price', sortOrder: 'asc');
  return paginated.items;
});
