import { CartsController } from '@/modules/carts/carts.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new CartsController();

/**
 * @openapi
 * /api/cart/items/{id}:
 *   put:
 *     summary: Update cart item quantity
 *     tags:
 *       - Cart
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - Quantity
 *             properties:
 *               Quantity:
 *                 type: integer
 *                 example: 3
 *     responses:
 *       200:
 *         description: Cart item quantity updated successfully.
 *       400:
 *         description: Insufficient stock.
 *       401:
 *         description: Unauthorized.
 *       404:
 *         description: Cart item not found or does not belong to the user.
 *   delete:
 *     summary: Remove item from shopping cart
 *     tags:
 *       - Cart
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Item removed successfully.
 *       401:
 *         description: Unauthorized.
 *       404:
 *         description: Cart item not found or does not belong to the user.
 */
export const PUT = withAuth((req, context) => controller.updateItem(req, context));
export const DELETE = withAuth((req, context) => controller.removeItem(req, context));
