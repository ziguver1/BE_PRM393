import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({
    required String email,
    required String password,
  });

  Future<User> googleLogin({
    required String email,
    required String fullName,
    String? avatar,
  });

  Future<User> register({
    required String fullName,
    required String email,
    required String password,
    required String verificationToken,
    String? phone,
    String? avatar,
  });

  Future<void> sendEmailOtp({required String email});
  
  Future<String> verifyEmailOtp({required String email, required String otp});

  Future<void> forgotPassword({required String email});
  
  Future<String> verifyResetOtp({required String email, required String otp});
  
  Future<void> resetPassword({
    required String passwordResetToken,
    required String newPassword,
    required String confirmPassword,
  });

  Future<void> logout();

  Future<User?> getSavedUser();
  Future<String?> getSavedAccessToken();
  Future<String?> getSavedRefreshToken();
  Future<bool> saveTokens(String accessToken, String refreshToken);
  Future<bool> saveUser(User user);
}
