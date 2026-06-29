import { NextRequest } from 'next/server';
import { CategoriesController } from '@/modules/categories/categories.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new CategoriesController();

/**
 * @openapi
 * /api/categories/{id}:
 *   get:
 *     summary: Retrieve a single category by ID
 *     tags:
 *       - Categories
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Category details.
 *       404:
 *         description: Category not found.
 *   put:
 *     summary: Update a category by ID (Admin only)
 *     tags:
 *       - Categories
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
 *               Name:
 *                 type: string
 *               Description:
 *                 type: string
 *               ImageUrl:
 *                 type: string
 *     responses:
 *       200:
 *         description: Category updated successfully.
 *       400:
 *         description: Validation error.
 *       401:
 *         description: Unauthorized.
 *       403:
 *         description: Forbidden.
 *       404:
 *         description: Category not found.
 *   delete:
 *     summary: Delete a category by ID (Admin only)
 *     tags:
 *       - Categories
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
 *         description: Category deleted successfully.
 *       401:
 *         description: Unauthorized.
 *       403:
 *         description: Forbidden.
 *       404:
 *         description: Category not found.
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
