import '../../domain/entities/user.dart';
import '../../domain/repository/auth_repository.dart';
import '../datasource/auth_local_data_source.dart';
import '../datasource/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(email: email, password: password);
    await _localDataSource.saveAccessToken(response.accessToken);
    await _localDataSource.saveRefreshToken(response.refreshToken);
    await _localDataSource.saveUser(response.user);
    return response.user;
  }

  @override
  Future<User> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? avatar,
  }) async {
    final response = await _remoteDataSource.register(
      fullName: fullName,
      email: email,
      password: password,
      phone: phone,
      avatar: avatar,
    );
    await _localDataSource.saveAccessToken(response.accessToken);
    await _localDataSource.saveRefreshToken(response.refreshToken);
    await _localDataSource.saveUser(response.user);
    return response.user;
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Clear locally even if API logout call fails (e.g. invalid tokens or offline)
    } finally {
      await _localDataSource.clearSession();
    }
  }

  @override
  Future<User?> getSavedUser() async {
    return _localDataSource.getUser();
  }

  @override
  Future<String?> getSavedAccessToken() async {
    return _localDataSource.getAccessToken();
  }

  @override
  Future<String?> getSavedRefreshToken() async {
    return _localDataSource.getRefreshToken();
  }

  @override
  Future<bool> saveTokens(String accessToken, String refreshToken) async {
    final s1 = await _localDataSource.saveAccessToken(accessToken);
    final s2 = await _localDataSource.saveRefreshToken(refreshToken);
    return s1 && s2;
  }

  @override
  Future<bool> saveUser(User user) async {
    if (user is UserModel) {
      return await _localDataSource.saveUser(user);
    }
    final userModel = UserModel(
      userId: user.userId,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      avatar: user.avatar,
      role: user.role,
    );
    return await _localDataSource.saveUser(userModel);
  }
}
