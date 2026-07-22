import { NextRequest } from 'next/server';
import { AuthController } from '@/modules/auth/auth.controller';

const controller = new AuthController();

/**
 * @openapi
 * /api/auth/register:
 *   post:
 *     summary: Register a new user
 *     tags:
 *       - Auth
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - FullName
 *               - Email
 *               - Password
 *               - verificationToken
 *             properties:
 *               FullName:
 *                 type: string
 *                 example: John Doe
 *               Email:
 *                 type: string
 *                 example: john@example.com
 *               Password:
 *                 type: string
 *                 example: password123
 *               verificationToken:
 *                 type: string
 *                 example: "eyJhbGciOiJIUzI1NiIsInR..."
 *               Phone:
 *                 type: string
 *                 example: "+123456789"
 *               Avatar:
 *                 type: string
 *                 example: "https://example.com/avatar.png"
 *               Role:
 *                 type: string
 *                 enum: [ADMIN, CUSTOMER]
 *                 example: CUSTOMER
 *     responses:
 *       201:
 *         description: User registered successfully.
 *       400:
 *         description: Validation or parameter error.
 *       409:
 *         description: Email already in use.
 */
export async function POST(req: NextRequest) {
  return controller.register(req);
}
