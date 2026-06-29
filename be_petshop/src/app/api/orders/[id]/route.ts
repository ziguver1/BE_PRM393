import { OrdersController } from '@/modules/orders/orders.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new OrdersController();

/**
 * @openapi
 * /api/orders/{id}:
 *   get:
 *     summary: Retrieve an order by ID
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
 *     responses:
 *       200:
 *         description: Full order details with items.
 *       401:
 *         description: Unauthorized.
 *       403:
 *         description: Forbidden (Customer accessing another user's order).
 *       404:
 *         description: Order not found.
 */
export const GET = withAuth((req, context) => controller.getById(req, context));
