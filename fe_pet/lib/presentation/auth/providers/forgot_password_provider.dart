import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/configs/providers.dart';

class ForgotPasswordState {
  final bool isLoading;
  final String? errorMessage;
  final String? passwordResetToken;
  final String? verifiedEmail;

  ForgotPasswordState({
    this.isLoading = false,
    this.errorMessage,
    this.passwordResetToken,
    this.verifiedEmail,
  });

  bool get isVerified => passwordResetToken != null && verifiedEmail != null;

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? passwordResetToken,
    String? verifiedEmail,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      passwordResetToken: passwordResetToken ?? this.passwordResetToken,
      verifiedEmail: verifiedEmail ?? this.verifiedEmail,
    );
  }
}

class ForgotPasswordNotifier extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() {
    return ForgotPasswordState();
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
      await repository.forgotPassword(email: email);
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
      final token = await repository.verifyResetOtp(email: email, otp: otp);
      state = state.copyWith(
        isLoading: false,
        passwordResetToken: token,
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

  Future<bool> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (state.passwordResetToken == null) {
      state = state.copyWith(
        errorMessage: 'Yêu cầu đặt lại mật khẩu không hợp lệ (thiếu token).',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.resetPassword(
        passwordResetToken: state.passwordResetToken!,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
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

  void reset() {
    state = ForgotPasswordState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final forgotPasswordProvider = NotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>(() {
  return ForgotPasswordNotifier();
});
