import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import 'providers/forgot_password_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      
      final success = await ref.read(forgotPasswordProvider.notifier).resetPassword(
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (success && mounted) {
        ref.read(forgotPasswordProvider.notifier).reset();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mật khẩu đã được đặt lại thành công. Vui lòng đăng nhập.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        context.go('/login');
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
        title: const Text('Thiết lập mật khẩu mới'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            ref.read(forgotPasswordProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Tạo mật khẩu mới',
                    style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Vui lòng nhập mật khẩu mới cho tài khoản của bạn. Mật khẩu phải có ít nhất 6 ký tự.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isLight ? AppColors.textSecondary : AppColors.textSecondaryDark,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  CustomTextField(
                    controller: TextEditingController(text: widget.email),
                    labelText: 'Tài khoản Email',
                    prefixIcon: Icons.email_outlined,
                    readOnly: true,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  CustomTextField(
                    controller: _newPasswordController,
                    labelText: 'Mật khẩu mới',
                    hintText: 'Nhập mật khẩu mới',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                      if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.l),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Xác nhận mật khẩu',
                    hintText: 'Nhập lại mật khẩu mới',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                      if (value != _newPasswordController.text) return 'Mật khẩu không khớp';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  CustomButton(
                    text: 'Lưu Mật Khẩu',
                    isLoading: state.isLoading,
                    onPressed: state.isLoading ? null : _onSubmit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
