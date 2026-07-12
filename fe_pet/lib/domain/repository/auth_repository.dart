import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({
    required String email,
    required String password,
  });

  Future<User> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? avatar,
  });

  Future<void> logout();

  Future<User?> getSavedUser();
  Future<String?> getSavedAccessToken();
  Future<String?> getSavedRefreshToken();
  Future<bool> saveTokens(String accessToken, String refreshToken);
  Future<bool> saveUser(User user);
}
