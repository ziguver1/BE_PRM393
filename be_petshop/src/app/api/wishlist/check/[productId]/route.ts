import { WishlistController } from '@/modules/wishlist/wishlist.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new WishlistController();

/**
 * @openapi
 * /api/wishlist/check/{productId}:
 *   get:
 *     summary: Check if a product is wishlisted (debugging only)
 *     tags:
 *       - Wishlist
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: productId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Check status success.
 */
export const GET = withAuth((req, context) => controller.checkWishlistStatus(req, context));
