import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/configs/providers.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repository/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(User user) => AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() => AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) => AuthState(status: AuthStatus.error, errorMessage: message);

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);

    // Connect Auth storage callbacks to ApiClient
    ref.read(apiClientProvider).init(
      tokenGetter: () => ref.read(authLocalDataSourceProvider).getAccessToken(),
      refreshTokenGetter: () => ref.read(authLocalDataSourceProvider).getRefreshToken(),
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
      final user = await _repository.getSavedUser();
      final token = await _repository.getSavedAccessToken();
      if (user != null && token != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = AuthState.loading();
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
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
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    state = AuthState.loading();
    try {
      await _repository.logout();
    } finally {
      state = AuthState.unauthenticated();
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
