import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasource/auth_local_data_source.dart';
import '../../data/datasource/auth_remote_data_source.dart';
import '../../data/repository/auth_repository_impl.dart';
import '../../domain/repository/auth_repository.dart';
import '../network/api_client.dart';
import '../../data/datasource/category_remote_data_source.dart';
import '../../data/datasource/product_remote_data_source.dart';
import '../../data/repository/category_repository_impl.dart';
import '../../data/repository/product_repository_impl.dart';
import '../../domain/repository/category_repository.dart';
import '../../domain/repository/product_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized in main()');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthLocalDataSource(prefs);
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthRemoteDataSource(client);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  final local = ref.watch(authLocalDataSourceProvider);
  return AuthRepositoryImpl(remote, local);
});

// Category Providers
final categoryRemoteDataSourceProvider = Provider<CategoryRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return CategoryRemoteDataSourceImpl(client);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final remote = ref.watch(categoryRemoteDataSourceProvider);
  return CategoryRepositoryImpl(remote);
});

// Product Providers
final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return ProductRemoteDataSourceImpl(client);
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final remote = ref.watch(productRemoteDataSourceProvider);
  return ProductRepositoryImpl(remote);
});
