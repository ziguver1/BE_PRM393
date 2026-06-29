import { NextRequest } from 'next/server';
import { CategoriesController } from '@/modules/categories/categories.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new CategoriesController();

/**
 * @openapi
 * /api/categories:
 *   get:
 *     summary: Retrieve all categories
 *     tags:
 *       - Categories
 *     responses:
 *       200:
 *         description: List of categories.
 *   post:
 *     summary: Create a new category (Admin only)
 *     tags:
 *       - Categories
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - Name
 *             properties:
 *               Name:
 *                 type: string
 *                 example: Dog Supplies
 *               Description:
 *                 type: string
 *                 example: Food, toys, and grooming items for dogs.
 *               ImageUrl:
 *                 type: string
 *                 example: https://example.com/dogs.png
 *     responses:
 *       201:
 *         description: Category created successfully.
 *       400:
 *         description: Validation error.
 *       401:
 *         description: Unauthorized.
 *       403:
 *         description: Forbidden.
 */
export async function GET(req: NextRequest) {
  return controller.getAll();
}

export const POST = withAuth((req) => controller.create(req), ['ADMIN']);
