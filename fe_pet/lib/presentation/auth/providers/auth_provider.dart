import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:dio/dio.dart';
import '../../../core/configs/providers.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repository/auth_repository.dart';
import '../../../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState({required this.status, this.user, this.errorMessage});

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(User user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() =>
      AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message);

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  String _extractErrorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['error'] ?? data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
      if (e.error is String && (e.error as String).trim().isNotEmpty) {
        return e.error as String;
      }
      if (e.message != null && e.message!.trim().isNotEmpty) {
        return e.message!;
      }
      return 'Login failed. Please try again.';
    }
    return e.toString();
  }

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);

    // Connect Auth storage callbacks to ApiClient
    ref
        .read(apiClientProvider)
        .init(
          tokenGetter: () =>
              ref.read(authLocalDataSourceProvider).getAccessToken(),
          refreshTokenGetter: () =>
              ref.read(authLocalDataSourceProvider).getRefreshToken(),
          onTokenRefreshed: (access, refresh) async {
            final ok = await _repository.saveTokens(access, refresh);
            return ok;
          },
          onLogoutRequired: () {
            logout();
          },
        );

    // restoreSession is asynchronous, so run after build
    Future.microtask(() => restoreSession());

    return AuthState.initial();
  }

  Future<void> restoreSession() async {
    state = AuthState.loading();
    try {
      final fbUser = fb.FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        final user = User(
          userId: fbUser.uid.hashCode,
          fullName: fbUser.displayName ?? 'Google User',
          email: fbUser.email ?? '',
          avatar: fbUser.photoURL,
          role: 'CUSTOMER',
        );
        state = AuthState.authenticated(user);
      } else {
        final user = await _repository.getSavedUser();
        final token = await _repository.getSavedAccessToken();
        if (user != null && token != null) {
          state = AuthState.authenticated(user);
        } else {
          state = AuthState.unauthenticated();
        }
      }
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = AuthState.loading();
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(_extractErrorMessage(e));
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? avatar,
  }) async {
    state = AuthState.loading();
    try {
      final user = await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        avatar: avatar,
      );
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(_extractErrorMessage(e));
    }
  }

  Future<void> loginWithGoogleUser({
    required String email,
    required String uid,
    required String displayName,
    String? photoUrl,
  }) async {
    state = AuthState.loading();
    try {
      final user = await _repository.googleLogin(
        email: email,
        fullName: displayName,
        avatar: photoUrl,
      );
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(_extractErrorMessage(e));
    }
  }

  Future<void> logout() async {
    state = AuthState.loading();
    try {
      await AuthService.signOut();
      await _repository.logout();
    } finally {
      state = AuthState.unauthenticated();
    }
  }

  void updateSessionUser(User updatedUser) {
    if (state.status == AuthStatus.authenticated) {
      state = AuthState.authenticated(updatedUser);
      _repository.saveUser(updatedUser);
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
