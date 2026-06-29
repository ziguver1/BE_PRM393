import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String? errorMessage;

  User? get currentUser => _authService.currentUser;

  AuthProvider() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _authService.login(
        email: email,
        password: password,
      );

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

      await _authService.register(
        email: email,
        password: password,
      );

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

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during Google Sign-In: ${e.code} - ${e.message}');
      errorMessage = e.message ?? 'Google login failed';
      return false;
    } catch (e, stackTrace) {
      debugPrint('Unexpected error during Google Sign-In: $e');
      debugPrint('$stackTrace');
      errorMessage = 'Google login failed: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }
}