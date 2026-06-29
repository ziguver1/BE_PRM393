import { NextRequest } from 'next/server';
import { AuthController } from '@/modules/auth/auth.controller';

const controller = new AuthController();

/**
 * @openapi
 * /api/auth/refresh:
 *   post:
 *     summary: Refresh expired access token
 *     tags:
 *       - Auth
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - RefreshToken
 *             properties:
 *               RefreshToken:
 *                 type: string
 *     responses:
 *       200:
 *         description: Token refreshed successfully, returns new access and refresh tokens.
 *       401:
 *         description: Invalid or expired refresh token.
 */
export async function POST(req: NextRequest) {
  return controller.refresh(req);
}
