import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/configs/providers.dart';

class EmailVerificationState {
  final bool isLoading;
  final String? errorMessage;
  final String? verificationToken;
  final String? verifiedEmail;

  EmailVerificationState({
    this.isLoading = false,
    this.errorMessage,
    this.verificationToken,
    this.verifiedEmail,
  });

  bool get isVerified => verificationToken != null && verifiedEmail != null;

  EmailVerificationState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? verificationToken,
    String? verifiedEmail,
    bool clearError = false,
  }) {
    return EmailVerificationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      verificationToken: verificationToken ?? this.verificationToken,
      verifiedEmail: verifiedEmail ?? this.verifiedEmail,
    );
  }
}

class EmailVerificationNotifier extends Notifier<EmailVerificationState> {
  @override
  EmailVerificationState build() {
    return EmailVerificationState();
  }

  String _extractErrorMessage(Object e) {
    if (e is DioException) {
      if (e.error is String && (e.error as String).isNotEmpty) {
        return e.error as String;
      }
      final data = e.response?.data;
      if (data is Map) {
        final message = data['error'] ?? data['message'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
      return 'Lỗi kết nối. Vui lòng thử lại.';
    }
    return e.toString();
  }

  Future<bool> sendOtp(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.sendEmailOtp(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _extractErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final token = await repository.verifyEmailOtp(email: email, otp: otp);
      state = state.copyWith(
        isLoading: false,
        verificationToken: token,
        verifiedEmail: email,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _extractErrorMessage(e),
      );
      return false;
    }
  }

  void reset() {
    state = EmailVerificationState();
  }
}

final emailVerificationProvider =
    NotifierProvider<EmailVerificationNotifier, EmailVerificationState>(() {
  return EmailVerificationNotifier();
});
