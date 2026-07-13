import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final Dio _authDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  bool isLoading = false;
  String? errorMessage;
  String? _backendToken;

  String? get backendToken => _backendToken;
  User? get currentUser => _authService.currentUser;
  bool get isAuthenticated => currentUser != null && _backendToken != null;

  AuthProvider() {
    ApiClient().init(
      tokenGetter: () => _backendToken,
      refreshTokenGetter: () => null,
      onTokenRefreshed: (access, refresh) async {
        _backendToken = access;
        return true;
      },
      onLogoutRequired: () {
        _backendToken = null;
        notifyListeners();
      },
    );

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        _backendToken = null;
      }
      notifyListeners();
    });
  }

  String _getBackendUrl() {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    if (kIsWeb) return 'http://localhost:3000/api';
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:3000/api';
      }
    } catch (_) {}
    return 'http://localhost:3000/api';
  }

  Future<void> _syncWithBackend(
    String email,
    String password, {
    String? fullName,
  }) async {
    final baseUrl = _getBackendUrl();
    try {
      debugPrint('Syncing with backend: $baseUrl/auth/login for $email');
      final response = await _authDio.post(
        '$baseUrl/auth/login',
        data: {'Email': email, 'Password': password},
      );
      if (response.statusCode == 200) {
        _backendToken = response.data['accessToken'];
        debugPrint('Backend login successful. Token acquired.');
      }
    } on DioException catch (e) {
      // User may not exist in backend database yet, try to register
      if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        debugPrint('User not found on backend. Attempting registration...');
        try {
          final regResponse = await _authDio.post(
            '$baseUrl/auth/register',
            data: {
              'FullName': fullName ?? email.split('@').first,
              'Email': email,
              'Password': password,
              'Role': 'CUSTOMER',
            },
          );
          if (regResponse.statusCode == 201) {
            _backendToken = regResponse.data['accessToken'];
            debugPrint('Backend register & login successful.');
          }
        } catch (regErr) {
          debugPrint('Backend registration error: $regErr');
        }
      } else {
        debugPrint(
          'Backend login error (${e.response?.statusCode}): ${e.message}',
        );
      }
    } catch (e) {
      debugPrint('Unexpected backend sync error: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _authService.login(email: email, password: password);

      // Sync with our backend API
      await _syncWithBackend(email, password);

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? 'Login failed';
      return false;
    } catch (e) {
      errorMessage = 'Something went wrong';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _authService.register(email: email, password: password);

      // Register and login to our backend API
      await _syncWithBackend(email, password);

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? 'Register failed';
      return false;
    } catch (e) {
      errorMessage = 'Something went wrong';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final result = await _authService.loginWithGoogle();

      if (result == null) {
        errorMessage = 'Google login was cancelled';
        return false;
      }

      // Sync with our backend API using Google UID as password
      final user = result.user;
      if (user != null && user.email != null) {
        await _syncWithBackend(
          user.email!,
          user.uid,
          fullName: user.displayName,
        );
      }

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthProvider Google Sign-In Error: ${e.code} - ${e.message}');
      errorMessage = e.message ?? 'Google login failed';
      return false;
    } catch (e) {
      debugPrint('Unexpected error during Google Sign-In: $e');
      errorMessage = 'Google login failed: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _backendToken = null;
    notifyListeners();
  }
}
