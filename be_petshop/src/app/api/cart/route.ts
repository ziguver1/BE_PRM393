import { CartsController } from '@/modules/carts/carts.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new CartsController();

/**
 * @openapi
 * /api/cart:
 *   get:
 *     summary: Retrieve authenticated user's cart
 *     tags:
 *       - Cart
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Cart details with items and calculated total.
 *       401:
 *         description: Unauthorized.
 */
export const GET = withAuth((req, context) => controller.getCart(req, context));
