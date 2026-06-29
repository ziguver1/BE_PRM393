import { NextRequest } from 'next/server';
import { ProductsController } from '@/modules/products/products.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new ProductsController();

/**
 * @openapi
 * /api/products/{id}:
 *   get:
 *     summary: Retrieve a single product by ID
 *     tags:
 *       - Products
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Product details.
 *       404:
 *         description: Product not found.
 *   put:
 *     summary: Update a product by ID (Admin only)
 *     tags:
 *       - Products
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
 *             properties:
 *               CategoryId:
 *                 type: integer
 *               Name:
 *                 type: string
 *               Description:
 *                 type: string
 *               Price:
 *                 type: number
 *               Stock:
 *                 type: integer
 *               ImageUrl:
 *                 type: string
 *     responses:
 *       200:
 *         description: Product updated successfully.
 *       400:
 *         description: Validation or Category ID validation error.
 *       401:
 *         description: Unauthorized.
 *       403:
 *         description: Forbidden.
 *       404:
 *         description: Product not found.
 *   delete:
 *     summary: Delete a product by ID (Admin only)
 *     tags:
 *       - Products
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
 *         description: Product deleted successfully.
 *       401:
 *         description: Unauthorized.
 *       403:
 *         description: Forbidden.
 *       404:
 *         description: Product not found.
 */
export async function GET(req: NextRequest, props: { params: Promise<{ id: string }> }) {
  const resolvedParams = await props.params;
  return controller.getById(req, { params: resolvedParams });
}

export const PUT = withAuth(
  (req, context) => controller.update(req, context),
  ['ADMIN']
);

export const DELETE = withAuth(
  (req, context) => controller.delete(req, context),
  ['ADMIN']
);
