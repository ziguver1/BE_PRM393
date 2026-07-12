import '../models/category_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> getCategoryById(int id);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final ApiClient _apiClient;

  CategoryRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _apiClient.dio.get(ApiConstants.categories);
    final list = response.data as List<dynamic>;
    return list.map((item) => CategoryModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<CategoryModel> getCategoryById(int id) async {
    final response = await _apiClient.dio.get('${ApiConstants.categories}/$id');
    return CategoryModel.fromJson(response.data as Map<String, dynamic>);
  }
}
