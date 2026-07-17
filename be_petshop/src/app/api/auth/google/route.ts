import { NextRequest } from 'next/server';
import { AuthController } from '@/modules/auth/auth.controller';

const controller = new AuthController();

/**
 * @openapi
 * /api/auth/google:
 *   post:
 *     summary: Authenticate via Google (sign-in or auto-register)
 *     tags:
 *       - Auth
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - Email
 *               - FullName
 *             properties:
 *               Email:
 *                 type: string
 *                 example: john@example.com
 *               FullName:
 *                 type: string
 *                 example: John Doe
 *               Avatar:
 *                 type: string
 *                 example: https://example.com/avatar.png
 *     responses:
 *       200:
 *         description: Authenticated successfully, returns JWT access and refresh tokens.
 *       400:
 *         description: Bad request.
 */
export async function POST(req: NextRequest) {
  return controller.googleLogin(req);
}
