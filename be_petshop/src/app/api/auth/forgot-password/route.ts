import { NextRequest } from 'next/server';
import AuthController from '../../../../modules/auth/auth.controller';

const authController = new AuthController();

export async function POST(req: NextRequest) {
  return authController.forgotPassword(req);
}
