import '../../domain/entities/category.dart';
import '../../domain/repository/category_repository.dart';
import '../datasource/category_remote_data_source.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _remoteDataSource;

  CategoryRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Category>> getCategories() {
    return _remoteDataSource.getCategories();
  }

  @override
  Future<Category> getCategoryById(int id) {
    return _remoteDataSource.getCategoryById(id);
  }
}
