import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/email_verification_provider.dart';
import '../providers/forgot_password_provider.dart';

enum OtpDialogPurpose { emailVerification, passwordReset }

class OtpVerificationDialog extends ConsumerStatefulWidget {
  final String email;
  final OtpDialogPurpose purpose;

  const OtpVerificationDialog({
    super.key, 
    required this.email,
    this.purpose = OtpDialogPurpose.emailVerification,
  });

  @override
  ConsumerState<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends ConsumerState<OtpVerificationDialog> {
  final int _otpLength = 6;
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text;
    if (otp.length < _otpLength) return;

    final success = widget.purpose == OtpDialogPurpose.emailVerification
        ? await ref.read(emailVerificationProvider.notifier).verifyOtp(widget.email, otp)
        : await ref.read(forgotPasswordProvider.notifier).verifyOtp(widget.email, otp);
    
    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _resendOtp() async {
    widget.purpose == OtpDialogPurpose.emailVerification
        ? await ref.read(emailVerificationProvider.notifier).sendOtp(widget.email)
        : await ref.read(forgotPasswordProvider.notifier).sendOtp(widget.email);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.purpose == OtpDialogPurpose.emailVerification
        ? ref.watch(emailVerificationProvider).isLoading
        : ref.watch(forgotPasswordProvider).isLoading;
    final errorMessage = widget.purpose == OtpDialogPurpose.emailVerification
        ? ref.watch(emailVerificationProvider).errorMessage
        : ref.watch(forgotPasswordProvider).errorMessage;

    final isLight = Theme.of(context).brightness == Brightness.light;
    final currentText = _otpController.text;
    final isReadyToSubmit = currentText.length == _otpLength;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: isLight ? AppColors.surface : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xxl * 1.2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Xác Thực Email',
                    style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isLight ? AppColors.textSecondary : AppColors.textSecondaryDark,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(text: 'Mã OTP gồm $_otpLength chữ số vừa được gửi đến\n'),
                        TextSpan(
                          text: widget.email,
                          style: TextStyle(
                            color: isLight ? AppColors.textPrimary : AppColors.textPrimaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  
                  // OTP Inputs Stack
                  SizedBox(
                    height: 60,
                    child: Stack(
                      children: [
                        // Visual boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            _otpLength,
                            (index) {
                              final char = index < currentText.length ? currentText[index] : '';
                              final isFocused = _focusNode.hasFocus && 
                                                ((index == currentText.length) || 
                                                (currentText.length == _otpLength && index == _otpLength - 1));
                              
                              return Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 50),
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: isLight ? AppColors.inputBackground : AppColors.inputBackgroundDark,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isFocused 
                                            ? AppColors.primary 
                                            : (isLight ? AppColors.inputBorder : AppColors.inputBorderDark),
                                        width: isFocused ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.03),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      char,
                                      style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Hidden TextField to capture input natively
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0, // completely invisible
                            child: TextField(
                              controller: _otpController,
                              focusNode: _focusNode,
                              keyboardType: TextInputType.number,
                              maxLength: _otpLength,
                              showCursor: false,
                              enableInteractiveSelection: false,
                              autofocus: true,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (_) {
                                setState(() {}); // Trigger rebuild to update visual boxes
                              },
                              decoration: const InputDecoration(
                                counterText: '', // Hide default max length counter
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.l),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage,
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: AppSpacing.xxl),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: CustomButton(
                      text: 'Xác Nhận',
                      isLoading: isLoading,
                      onPressed: isReadyToSubmit && !isLoading ? _verifyOtp : null,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.m),
                  
                  TextButton(
                    onPressed: isLoading ? null : _resendOtp,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Gửi lại mã OTP',
                      style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  )
                ],
              ),
            ),
            
            // Premium Close Button
            Positioned(
              right: 16,
              top: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isLight ? Colors.grey.shade100 : Colors.grey.shade800,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isLight ? Colors.black54 : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

