import { z } from 'zod';

export const registerSchema = z.object({
  FullName: z.string().min(2, 'Full name must be at least 2 characters'),
  Email: z.string().email('Invalid email address'),
  Password: z.string().min(6, 'Password must be at least 6 characters'),
  Phone: z.string().optional().nullable(),
  Avatar: z.string().url('Invalid avatar URL').optional().nullable(),
  Role: z.enum(['ADMIN', 'CUSTOMER']).default('CUSTOMER'),
  verificationToken: z.string({ required_error: 'Verification token is required' }),
});

export const loginSchema = z.object({
  Email: z.string().email('Invalid email address'),
  Password: z.string().min(1, 'Password is required'),
});

export const refreshSchema = z.object({
  RefreshToken: z.string().min(1, 'Refresh token is required'),
});

export const sendEmailOtpSchema = z.object({
  email: z.string().email('Invalid email address'),
});

export const verifyEmailOtpSchema = z.object({
  email: z.string().email('Invalid email address'),
  otp: z.string().length(6, 'OTP must be 6 digits'),
});

export const forgotPasswordSchema = z.object({
  email: z.string().email('Invalid email address'),
});

export const verifyResetOtpSchema = z.object({
  email: z.string().email('Invalid email address'),
  otp: z.string().length(6, 'OTP must be 6 digits'),
});

export const resetPasswordSchema = z.object({
  passwordResetToken: z.string({ required_error: 'Token is required' }),
  newPassword: z.string().min(6, 'Password must be at least 6 characters'),
  confirmPassword: z.string().min(6, 'Password must be at least 6 characters'),
}).refine((data) => data.newPassword === data.confirmPassword, {
  message: "Passwords don't match",
  path: ["confirmPassword"],
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type RefreshInput = z.infer<typeof refreshSchema>;
export type SendEmailOtpInput = z.infer<typeof sendEmailOtpSchema>;
export type VerifyEmailOtpInput = z.infer<typeof verifyEmailOtpSchema>;
export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>;
export type VerifyResetOtpInput = z.infer<typeof verifyResetOtpSchema>;
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>;
