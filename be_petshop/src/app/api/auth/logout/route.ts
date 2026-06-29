import { NextRequest } from 'next/server';
import { AuthController } from '@/modules/auth/auth.controller';

const controller = new AuthController();

/**
 * @openapi
 * /api/auth/logout:
 *   post:
 *     summary: Invalidate user session / logout
 *     tags:
 *       - Auth
 *     responses:
 *       200:
 *         description: Logout successful.
 */
export async function POST(req: NextRequest) {
  return controller.logout();
}
