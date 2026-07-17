import { UserController } from '@/modules/users/user.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new UserController();

/**
 * @openapi
 * /api/users/profile/avatar:
 *   post:
 *     summary: Upload new profile avatar
 *     description: Uploads an image to Cloudinary and registers the URL on the user record. Maximum size 5MB.
 *     tags:
 *       - Users
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - file
 *             properties:
 *               file:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: Avatar uploaded and profile updated successfully.
 *       400:
 *         description: Invalid image file or size limit exceeded.
 *       401:
 *         description: Unauthorized.
 */
export const POST = withAuth((req, context) => controller.uploadAvatar(req, context));
export const runtime = 'nodejs';
