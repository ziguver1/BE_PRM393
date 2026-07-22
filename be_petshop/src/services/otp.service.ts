import crypto from 'crypto';
import prisma from '../lib/prisma';
import { AppError } from '../middleware/error.middleware';

export type OtpPurpose = 'EMAIL_VERIFICATION' | 'PASSWORD_RESET';

export class OtpService {
  /**
   * Generates a 6-digit OTP, enforces rate limits, hashes it, and saves to the database.
   */
  async createOtp(email: string, purpose: OtpPurpose): Promise<string> {
    // Check rate limit: 1 OTP / 60 seconds
    const existingOtp = await prisma.otpVerification.findUnique({
      where: {
        email_purpose: {
          email,
          purpose
        }
      }
    });

    if (existingOtp) {
      const timeSinceLastOtp = Date.now() - existingOtp.createdAt.getTime();
      if (timeSinceLastOtp < 60000) {
        throw new AppError('Please wait 60 seconds before requesting a new OTP.', 429);
      }
    }

    // Generate 6 digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpHash = crypto.createHash('sha256').update(otp).digest('hex');
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

    await prisma.otpVerification.upsert({
      where: {
        email_purpose: {
          email,
          purpose
        }
      },
      update: {
        otpHash,
        expiresAt,
        attempts: 0,
        createdAt: new Date()
      },
      create: {
        email,
        otpHash,
        purpose,
        expiresAt,
        attempts: 0
      }
    });

    return otp;
  }

  /**
   * Verifies an OTP based on expiration, max attempts, and hash matching.
   * Cleans up the OTP record if verified or expired.
   */
  async verifyOtp(email: string, otp: string, purpose: OtpPurpose): Promise<boolean> {
    const record = await prisma.otpVerification.findUnique({
      where: {
        email_purpose: {
          email,
          purpose
        }
      }
    });

    if (!record) {
      throw new AppError('OTP not found or expired.', 400);
    }

    if (record.expiresAt < new Date()) {
      await prisma.otpVerification.delete({
        where: { email_purpose: { email, purpose } }
      });
      throw new AppError('OTP has expired.', 400);
    }

    if (record.attempts >= 5) {
      await prisma.otpVerification.delete({
        where: { email_purpose: { email, purpose } }
      });
      throw new AppError('Maximum attempts reached. Please request a new OTP.', 400);
    }

    const inputHash = crypto.createHash('sha256').update(otp).digest('hex');
    if (record.otpHash !== inputHash) {
      await prisma.otpVerification.update({
        where: { email_purpose: { email, purpose } },
        data: { attempts: record.attempts + 1 }
      });
      throw new AppError('Invalid OTP.', 400);
    }

    // OTP is valid, cleanup
    await prisma.otpVerification.delete({
      where: { email_purpose: { email, purpose } }
    });

    return true;
  }
}
