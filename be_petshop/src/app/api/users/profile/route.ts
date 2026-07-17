import { UserController } from '@/modules/users/user.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new UserController();

/**
 * @openapi
 * /api/users/profile:
 *   get:
 *     summary: Get authenticated user profile details
 *     tags:
 *       - Users
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Profile details loaded successfully.
 *       401:
 *         description: Unauthorized.
 *   patch:
 *     summary: Update authenticated user profile
 *     tags:
 *       - Users
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               fullName:
 *                 type: string
 *               phoneNumber:
 *                 type: string
 *               gender:
 *                 type: string
 *               birthday:
 *                 type: string
 *               bio:
 *                 type: string
 *     responses:
 *       200:
 *         description: Profile updated successfully.
 *       400:
 *         description: Invalid input data.
 *       412:
 *         description: Precondition Failed / Validation error.
 */
export const GET = withAuth((req, context) => controller.getProfile(req, context));
export const PATCH = withAuth((req, context) => controller.updateProfile(req, context));
