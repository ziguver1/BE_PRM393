import { AppError } from '../middleware/error.middleware';

export class EmailService {
  private readonly apiKey: string;
  private readonly fromEmail: string;
  private readonly fromName: string;

  constructor() {
    this.apiKey = process.env.BREVO_API_KEY || '';
    this.fromEmail = process.env.MAIL_FROM_EMAIL || 'noreply@pawmart.com';
    this.fromName = process.env.MAIL_FROM_NAME || 'PawMart Security';
  }

  async sendEmail(toEmail: string, subject: string, htmlContent: string) {
    if (!this.apiKey) {
      console.warn('BREVO_API_KEY is not set. Skipping email send.');
      return;
    }

    try {
      const response = await fetch('https://api.brevo.com/v3/smtp/email', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'api-key': this.apiKey,
          'accept': 'application/json'
        },
        body: JSON.stringify({
          sender: { name: this.fromName, email: this.fromEmail },
          to: [{ email: toEmail }],
          subject,
          htmlContent
        })
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => null);
        console.error('Brevo API Error:', errorData);
        throw new AppError('Failed to send email. Please try again later.', 500);
      }
    } catch (error) {
      console.error('EmailService Error:', error);
      throw new AppError('Failed to send email.', 500);
    }
  }

  async sendVerificationOtp(toEmail: string, otp: string) {
    const subject = 'Your PawMart verification code';
    const htmlContent = `
      <div style="font-family: Arial, sans-serif; padding: 20px; max-width: 600px; margin: auto; border: 1px solid #ddd; border-radius: 10px;">
        <h2 style="color: #333;">Welcome to PawMart!</h2>
        <p>Your verification code is:</p>
        <h1 style="font-size: 32px; letter-spacing: 5px; color: #4CAF50;">${otp}</h1>
        <p>This code expires in 5 minutes.</p>
        <p style="color: red; font-size: 12px;">Security warning: Never share this code with anyone. PawMart will never ask for this code.</p>
      </div>
    `;
    await this.sendEmail(toEmail, subject, htmlContent);
  }

  async sendPasswordResetOtp(toEmail: string, otp: string) {
    const subject = 'Your PawMart Password Reset Code';
    const htmlContent = `
      <div style="font-family: Arial, sans-serif; padding: 20px; max-width: 600px; margin: auto; border: 1px solid #ddd; border-radius: 10px;">
        <h2 style="color: #333;">Password Reset Request</h2>
        <p>Your password reset code is:</p>
        <h1 style="font-size: 32px; letter-spacing: 5px; color: #4CAF50;">${otp}</h1>
        <p>This code expires in 5 minutes.</p>
        <p>If you did not request this password reset, please ignore this email.</p>
        <p style="color: red; font-size: 12px;">Security warning: Never share this code with anyone. PawMart will never ask for this code.</p>
      </div>
    `;
    await this.sendEmail(toEmail, subject, htmlContent);
  }
}
