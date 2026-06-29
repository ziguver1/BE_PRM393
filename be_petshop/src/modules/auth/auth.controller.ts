import { NextRequest, NextResponse } from 'next/server';
import { AuthService } from '../../services/auth.service';
import { registerSchema, loginSchema, refreshSchema } from '../../validators/auth.validator';
import { handleError } from '../../middleware/error.middleware';

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
}
export default AuthController;
