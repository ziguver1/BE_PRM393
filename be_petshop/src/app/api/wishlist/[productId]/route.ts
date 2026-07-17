import { WishlistController } from '@/modules/wishlist/wishlist.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new WishlistController();

/**
 * @openapi
 * /api/wishlist/{productId}:
 *   post:
 *     summary: Add a product to the user's wishlist
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
 *         description: Added successfully.
 *   delete:
 *     summary: Remove a product from the user's wishlist
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
 *         description: Removed successfully.
 */
export const POST = withAuth((req, context) => controller.addToWishlist(req, context));
export const DELETE = withAuth((req, context) => controller.removeFromWishlist(req, context));
