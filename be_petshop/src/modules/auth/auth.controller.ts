import { NextRequest, NextResponse } from 'next/server';
import { AuthService } from '../../services/auth.service';
import { registerSchema, loginSchema, refreshSchema } from '../../validators/auth.validator';
import { handleError, AppError } from '../../middleware/error.middleware';
import { TokenPayload } from '../../lib/jwt';

const authService = new AuthService();

export class AuthController {
  async register(req: NextRequest) {
    try {
      const body = await req.json();
      const validated = registerSchema.parse(body);
      const result = await authService.register(validated);
      return NextResponse.json(result, { status: 201 });
    } catch (error) {
      return handleError(error);
    }
  }

  async login(req: NextRequest) {
    try {
      const body = await req.json();
      const validated = loginSchema.parse(body);
      const result = await authService.login(validated);
      return NextResponse.json(result, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async googleLogin(req: NextRequest) {
    try {
      const body = await req.json();
      if (!body.Email || !body.FullName) {
        throw new AppError('Email and FullName are required for Google login.', 400);
      }
      const result = await authService.googleLogin({
        Email: body.Email,
        FullName: body.FullName,
        Avatar: body.Avatar,
      });
      return NextResponse.json(result, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async refresh(req: NextRequest) {
    try {
      const body = await req.json();
      const validated = refreshSchema.parse(body);
      const result = await authService.refresh(validated.RefreshToken);
      return NextResponse.json(result, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async logout() {
    return NextResponse.json(
      { message: 'Logged out successfully.' },
      { status: 200 }
    );
  }

  async updateFcmToken(req: NextRequest, context: { user: TokenPayload }) {
    try {
      const userId = context.user.userId;
      const body = await req.json();
      const fcmToken = body.fcmToken;

      const tokenValue = (fcmToken === null || fcmToken === '') ? null : fcmToken;
      if (tokenValue === undefined) {
        throw new AppError('fcmToken is required.', 400);
      }

      await authService.updateFcmToken(userId, tokenValue);
      return NextResponse.json({
        success: true,
        message: tokenValue ? 'FCM Device Token updated successfully.' : 'FCM Device Token cleared successfully.'
      }, { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }
}
export default AuthController;
