import { OrdersController } from '@/modules/orders/orders.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new OrdersController();

/**
 * @openapi
 * /api/orders/{id}/status:
 *   put:
 *     summary: Update an order status (Admin only)
 *     tags:
 *       - Orders
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
 *               - Status
 *             properties:
 *               Status:
 *                 type: string
 *                 enum: [PENDING, PROCESSING, SHIPPING, DELIVERED, CANCELLED]
 *                 example: PROCESSING
 *     responses:
 *       200:
 *         description: Order status updated successfully.
 *       400:
 *         description: Validation error.
 *       401:
 *         description: Unauthorized.
 *       403:
 *         description: Forbidden (Admin only).
 *       404:
 *         description: Order not found.
 */
export const PUT = withAuth(
  (req, context) => controller.updateStatus(req, context),
  ['ADMIN']
);
