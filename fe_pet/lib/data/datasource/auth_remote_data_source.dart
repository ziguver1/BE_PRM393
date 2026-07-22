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

  Future<AuthResponseModel> googleLogin({
    required String email,
    required String fullName,
    String? avatar,
  }) async {
    final response = await _client.dio.post('/auth/google', data: {
      'Email': email,
      'FullName': fullName,
      if (avatar != null) 'Avatar': avatar,
    });
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String password,
    required String verificationToken,
    String? phone,
    String? avatar,
  }) async {
    final response = await _client.dio.post('/auth/register', data: {
      'FullName': fullName,
      'Email': email,
      'Password': password,
      'verificationToken': verificationToken,
      'Phone': phone,
      'Avatar': avatar,
    });
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> sendEmailOtp({required String email}) async {
    await _client.dio.post('/auth/send-email-otp', data: {
      'email': email,
    });
  }

  Future<String> verifyEmailOtp({required String email, required String otp}) async {
    final response = await _client.dio.post('/auth/verify-email-otp', data: {
      'email': email,
      'otp': otp,
    });
    return response.data['verificationToken'] as String;
  }
  Future<void> forgotPassword({required String email}) async {
    await _client.dio.post('/auth/forgot-password', data: {
      'email': email,
    });
  }

  Future<String> verifyResetOtp({required String email, required String otp}) async {
    final response = await _client.dio.post('/auth/verify-reset-otp', data: {
      'email': email,
      'otp': otp,
    });
    return response.data['passwordResetToken'] as String;
  }

  Future<void> resetPassword({
    required String passwordResetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _client.dio.post('/auth/reset-password', data: {
      'passwordResetToken': passwordResetToken,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }
  Future<void> logout() async {
    await _client.dio.post('/auth/logout');
  }
}
