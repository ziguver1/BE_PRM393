import { OrdersController } from '@/modules/orders/orders.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new OrdersController();

/**
 * @openapi
 * /api/orders:
 *   post:
 *     summary: Place a new order from cart
 *     tags:
 *       - Orders
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - shippingLatitude
 *               - shippingLongitude
 *             properties:
 *               shippingLatitude:
 *                 type: number
 *                 example: 10.8660
 *               shippingLongitude:
 *                 type: number
 *                 example: 106.7951
 *               selectedCartItemIds:
 *                 type: array
 *                 items:
 *                   type: integer
 *                 example: [1, 2]
 *     responses:
 *       201:
 *         description: Order created successfully, cart emptied, stock decreased.
 *       400:
 *         description: Empty cart or insufficient product stock.
 *       401:
 *         description: Unauthorized.
 *   get:
 *     summary: Retrieve order history
 *     description: Customers see their own order history. Admins see all orders in the system.
 *     tags:
 *       - Orders
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of orders.
 *       401:
 *         description: Unauthorized.
 */
export const POST = withAuth((req, context) => controller.create(req, context));
export const GET = withAuth((req, context) => controller.getAll(req, context));
