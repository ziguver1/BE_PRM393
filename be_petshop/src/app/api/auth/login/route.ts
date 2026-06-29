import { NextRequest } from 'next/server';
import { AuthController } from '@/modules/auth/auth.controller';

const controller = new AuthController();

/**
 * @openapi
 * /api/auth/login:
 *   post:
 *     summary: Authenticate user & get tokens
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
 *               - Password
 *             properties:
 *               Email:
 *                 type: string
 *                 example: john@example.com
 *               Password:
 *                 type: string
 *                 example: password123
 *     responses:
 *       200:
 *         description: Authenticated successfully, returns JWT access and refresh tokens.
 *       401:
 *         description: Invalid credentials.
 */
export async function POST(req: NextRequest) {
  return controller.login(req);
}
