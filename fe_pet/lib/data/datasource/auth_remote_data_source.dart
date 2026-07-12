import '../../core/network/api_client.dart';
import '../models/auth_response_model.dart';

class AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSource(this._client);

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.dio.post('/auth/login', data: {
      'Email': email,
      'Password': password,
    });
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? avatar,
  }) async {
    final response = await _client.dio.post('/auth/register', data: {
      'FullName': fullName,
      'Email': email,
      'Password': password,
      'Phone': phone,
      'Avatar': avatar,
    });
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _client.dio.post('/auth/logout');
  }
}
