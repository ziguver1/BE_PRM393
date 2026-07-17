import { WishlistController } from '@/modules/wishlist/wishlist.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new WishlistController();

/**
 * @openapi
 * /api/wishlist:
 *   get:
 *     summary: Get all wishlisted products for authenticated user
 *     tags:
 *       - Wishlist
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Wishlist retrieval success.
 */
export const GET = withAuth((req, context) => controller.getWishlist(req, context));
