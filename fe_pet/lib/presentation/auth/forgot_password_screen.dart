import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import 'providers/forgot_password_provider.dart';
import 'widgets/otp_verification_dialog.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final email = _emailController.text.trim();

      final success = await ref.read(forgotPasswordProvider.notifier).sendOtp(email);

      if (success && mounted) {
        final isVerified = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => OtpVerificationDialog(
            email: email,
            purpose: OtpDialogPurpose.passwordReset,
          ),
        );

        if (isVerified == true && mounted) {
          context.push('/reset-password', extra: email);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    ref.listen<ForgotPasswordState>(forgotPasswordProvider, (previous, next) {
      if (next.errorMessage != null && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: isLight ? AppColors.background : AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            ref.read(forgotPasswordProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Khôi phục mật khẩu',
                  style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Vui lòng nhập địa chỉ email đã đăng ký tài khoản. Chúng tôi sẽ gửi hướng dẫn thiết lập lại mật khẩu mới cho bạn.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isLight ? AppColors.textSecondary : AppColors.textSecondaryDark,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email khôi phục',
                  hintText: 'Nhập địa chỉ email của bạn',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Email không đúng định dạng';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xxxl),
                CustomButton(
                  text: 'Gửi Hướng Dẫn',
                  isLoading: state.isLoading,
                  onPressed: state.isLoading ? null : _onSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
