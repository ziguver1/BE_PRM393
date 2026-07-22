import { NextRequest } from 'next/server';
import { AuthController } from '@/modules/auth/auth.controller';

const controller = new AuthController();

/**
 * @openapi
 * /api/auth/send-email-otp:
 *   post:
 *     summary: Send OTP to verify email
 *     tags:
 *       - Auth
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *             properties:
 *               email:
 *                 type: string
 *                 example: user@gmail.com
 *     responses:
 *       200:
 *         description: OTP sent successfully.
 *       400:
 *         description: Validation error.
 *       409:
 *         description: Email already in use.
 *       429:
 *         description: Rate limit exceeded.
 */
export async function POST(req: NextRequest) {
  return controller.sendEmailOtp(req);
}
