import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import 'providers/auth_provider.dart';
import 'providers/email_verification_provider.dart';
import 'widgets/otp_verification_dialog.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset the email verification state when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(emailVerificationProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onVerifyEmail() async {
    if (_emailFormKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final email = _emailController.text.trim();
      
      final success = await ref.read(emailVerificationProvider.notifier).sendOtp(email);
      
      if (success && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => OtpVerificationDialog(email: email),
        );
      }
    }
  }

  void _onRegister() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      
      final verificationToken = ref.read(emailVerificationProvider).verificationToken;
      if (verificationToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng xác thực email trước'), backgroundColor: AppColors.error),
        );
        return;
      }

      ref.read(authNotifierProvider.notifier).register(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            verificationToken: verificationToken,
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            avatar: 'https://api.dicebear.com/7.x/adventurer/png?seed=${_nameController.text.trim()}',
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final verificationState = ref.watch(emailVerificationProvider);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Reset email verification state if register fails (e.g. token expired)
        if (ref.read(emailVerificationProvider).isVerified) {
          ref.read(emailVerificationProvider.notifier).reset();
          _emailController.clear();
        }
      } else if (next.status == AuthStatus.authenticated) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    ref.listen<EmailVerificationState>(emailVerificationProvider, (previous, next) {
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

    final isLight = Theme.of(context).brightness == Brightness.light;
    final isVerified = verificationState.isVerified;

    return Scaffold(
      backgroundColor: isLight ? AppColors.background : AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Text(
                    'Tạo tài khoản mới',
                    style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text(
                    'Đăng ký để tham gia cộng đồng yêu thú cưng PawMart',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isLight ? AppColors.textSecondary : AppColors.textSecondaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                
                // Email Verification Section
                Form(
                  key: _emailFormKey,
                  child: CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    hintText: 'Nhập địa chỉ email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: isVerified,
                    suffixIcon: isVerified ? const Icon(Icons.check_circle, color: Colors.green) : null,
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
                ),
                const SizedBox(height: AppSpacing.l),
                
                if (!isVerified)
                  CustomButton(
                    text: 'Xác thực Email',
                    isLoading: verificationState.isLoading,
                    onPressed: _onVerifyEmail,
                  ),

                if (isVerified)
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _nameController,
                          labelText: 'Họ và tên',
                          hintText: 'Nhập họ và tên đầy đủ',
                          prefixIcon: Icons.person_outline_rounded,
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập họ tên';
                            }
                            if (value.length < 2) {
                              return 'Họ tên phải dài ít nhất 2 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.l),
                        CustomTextField(
                          controller: _phoneController,
                          labelText: 'Số điện thoại (tùy chọn)',
                          hintText: 'Nhập số điện thoại của bạn',
                          prefixIcon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppSpacing.l),
                        CustomTextField(
                          controller: _passwordController,
                          labelText: 'Mật khẩu',
                          hintText: 'Tạo mật khẩu đăng nhập',
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập mật khẩu';
                            }
                            if (value.length < 6) {
                              return 'Mật khẩu phải dài ít nhất 6 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.l),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          labelText: 'Xác nhận mật khẩu',
                          hintText: 'Nhập lại mật khẩu để xác nhận',
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng xác nhận mật khẩu';
                            }
                            if (value != _passwordController.text) {
                              return 'Mật khẩu xác nhận không khớp';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        CustomButton(
                          text: 'Đăng Ký',
                          isLoading: authState.status == AuthStatus.loading,
                          onPressed: _onRegister,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Đã có tài khoản? ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isLight ? AppColors.textSecondary : AppColors.textSecondaryDark,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Đăng nhập ngay',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
