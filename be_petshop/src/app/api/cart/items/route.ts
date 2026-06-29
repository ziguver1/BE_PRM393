import { CartsController } from '@/modules/carts/carts.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new CartsController();

/**
 * @openapi
 * /api/cart/items:
 *   post:
 *     summary: Add product to shopping cart
 *     tags:
 *       - Cart
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - ProductId
 *               - Quantity
 *             properties:
 *               ProductId:
 *                 type: integer
 *                 example: 1
 *               Quantity:
 *                 type: integer
 *                 example: 2
 *     responses:
 *       201:
 *         description: Item added or incremented in cart.
 *       400:
 *         description: Insufficient stock.
 *       401:
 *         description: Unauthorized.
 */
export const POST = withAuth((req, context) => controller.addItem(req, context));
