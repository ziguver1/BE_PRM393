import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import prisma from '../lib/prisma';
import { UserRepository } from '../repositories/user.repository';
import { RegisterInput, LoginInput, SendEmailOtpInput, VerifyEmailOtpInput, ForgotPasswordInput, VerifyResetOtpInput, ResetPasswordInput } from '../validators/auth.validator';
import { generateAccessToken, generateRefreshToken, verifyRefreshToken, TokenPayload, generateVerificationToken, verifyVerificationToken, generatePasswordResetToken, verifyPasswordResetToken } from '../lib/jwt';
import { AppError } from '../middleware/error.middleware';
import { EmailService } from './email.service';
import { OtpService } from './otp.service';

const userRepository = new UserRepository();
const emailService = new EmailService();
const otpService = new OtpService();

export class AuthService {
  async sendEmailOtp(input: SendEmailOtpInput) {
    const existingUser = await userRepository.findByEmail(input.email);
    if (existingUser) {
      throw new AppError('Email address is already registered.', 409);
    }

    const otp = await otpService.createOtp(input.email, 'EMAIL_VERIFICATION');
    await emailService.sendVerificationOtp(input.email, otp);

    return { message: 'OTP sent successfully.' };
  }

  async verifyEmailOtp(input: VerifyEmailOtpInput) {
    await otpService.verifyOtp(input.email, input.otp, 'EMAIL_VERIFICATION');
    
    const verificationToken = generateVerificationToken(input.email);
    return { verificationToken };
  }

  async forgotPassword(input: ForgotPasswordInput) {
    // We intentionally don't throw an error if the user doesn't exist
    // to prevent email enumeration.
    const existingUser = await userRepository.findByEmail(input.email);
    
    if (existingUser) {
      const otp = await otpService.createOtp(input.email, 'PASSWORD_RESET');
      await emailService.sendPasswordResetOtp(input.email, otp);
    }
    
    return { message: 'If the email exists, a verification code has been sent.' };
  }

  async verifyResetOtp(input: VerifyResetOtpInput) {
    await otpService.verifyOtp(input.email, input.otp, 'PASSWORD_RESET');
    
    const passwordResetToken = generatePasswordResetToken(input.email);
    return { passwordResetToken };
  }

  async resetPassword(input: ResetPasswordInput) {
    const verifiedPayload = verifyPasswordResetToken(input.passwordResetToken);
    
    if (!verifiedPayload) {
      throw new AppError('Invalid or expired password reset token.', 403);
    }

    const user = await userRepository.findByEmail(verifiedPayload.email);
    if (!user) {
      throw new AppError('User not found.', 404);
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(input.newPassword, salt);

    await userRepository.update(user.UserId, { PasswordHash: passwordHash });

    return { message: 'Password has been successfully reset.' };
  }

  async register(input: RegisterInput) {
    if (!input.verificationToken) {
      throw new AppError('Email verification required.', 403);
    }

    const verifiedPayload = verifyVerificationToken(input.verificationToken);
    if (!verifiedPayload) {
      throw new AppError('Invalid or expired verification token.', 403);
    }

    if (verifiedPayload.email !== input.Email) {
      throw new AppError('Verification token does not match the provided email.', 403);
    }

    const existing = await userRepository.findByEmail(input.Email);
    if (existing) {
      throw new AppError('Email address is already in use.', 409);
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(input.Password, salt);

    const user = await userRepository.create({
      FullName: input.FullName,
      Email: input.Email,
      PasswordHash: passwordHash,
      Phone: input.Phone,
      Avatar: input.Avatar,
      Role: input.Role,
    });

    const payload: TokenPayload = {
      userId: user.UserId,
      email: user.Email,
      role: user.Role,
    };

    const accessToken = generateAccessToken(payload);
    const refreshToken = generateRefreshToken(payload);

    return {
      user: {
        UserId: user.UserId,
        FullName: user.FullName,
        Email: user.Email,
        Phone: user.Phone,
        Avatar: user.Avatar,
        Role: user.Role,
      },
      accessToken,
      refreshToken,
    };
  }

  async login(input: LoginInput) {
    const user = await userRepository.findByEmail(input.Email);
    if (!user) {
      throw new AppError('Invalid email or password.', 401);
    }

    const isMatch = await bcrypt.compare(input.Password, user.PasswordHash);
    if (!isMatch) {
      throw new AppError('Invalid email or password.', 401);
    }

    const payload: TokenPayload = {
      userId: user.UserId,
      email: user.Email,
      role: user.Role,
    };

    const accessToken = generateAccessToken(payload);
    const refreshToken = generateRefreshToken(payload);

    return {
      user: {
        UserId: user.UserId,
        FullName: user.FullName,
        Email: user.Email,
        Phone: user.Phone,
        Avatar: user.Avatar,
        Role: user.Role,
      },
      accessToken,
      refreshToken,
    };
  }

  async refresh(token: string) {
    const decoded = verifyRefreshToken(token);
    if (!decoded) {
      throw new AppError('Invalid or expired refresh token.', 401);
    }

    const user = await userRepository.findById(decoded.userId);
    if (!user) {
      throw new AppError('User not found associated with this token.', 404);
    }

    const payload: TokenPayload = {
      userId: user.UserId,
      email: user.Email,
      role: user.Role,
    };

    const accessToken = generateAccessToken(payload);
    const newRefreshToken = generateRefreshToken(payload);

    return {
      accessToken,
      refreshToken: newRefreshToken,
    };
  }

  async googleLogin(input: { Email: string; FullName: string; Avatar?: string | null }) {
    let user = await userRepository.findByEmail(input.Email);

    if (!user) {
      const salt = await bcrypt.genSalt(10);
      const randomPassword = Math.random().toString(36).slice(-10) + Math.random().toString(36).slice(-10);
      const passwordHash = await bcrypt.hash(randomPassword, salt);

      user = await userRepository.create({
        FullName: input.FullName,
        Email: input.Email,
        PasswordHash: passwordHash,
        Phone: null,
        Avatar: input.Avatar || null,
        Role: 'CUSTOMER',
      });
    } else {
      if (!user.Avatar && input.Avatar) {
        await userRepository.update(user.UserId, { Avatar: input.Avatar });
        user.Avatar = input.Avatar;
      }
    }

    const payload: TokenPayload = {
      userId: user.UserId,
      email: user.Email,
      role: user.Role,
    };

    const accessToken = generateAccessToken(payload);
    const refreshToken = generateRefreshToken(payload);

    return {
      user: {
        UserId: user.UserId,
        FullName: user.FullName,
        Email: user.Email,
        Phone: user.Phone,
        Avatar: user.Avatar,
        Role: user.Role,
      },
      accessToken,
      refreshToken,
    };
  }

  async updateFcmToken(userId: number, fcmToken: string) {
    return userRepository.update(userId, { fcmToken });
  }
}
export default AuthService;
