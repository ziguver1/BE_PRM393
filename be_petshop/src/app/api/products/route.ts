import { NextRequest } from 'next/server';
import { ProductsController } from '@/modules/products/products.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new ProductsController();

/**
 * @openapi
 * /api/products:
 *   get:
 *     summary: Retrieve products with pagination, filtering, and sorting
 *     tags:
 *       - Products
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *       - in: query
 *         name: categoryId
 *         schema:
 *           type: integer
 *       - in: query
 *         name: minPrice
 *         schema:
 *           type: number
 *       - in: query
 *         name: maxPrice
 *         schema:
 *           type: number
 *       - in: query
 *         name: sortBy
 *         schema:
 *           type: string
 *           enum: [price, name, createdAt]
 *           default: createdAt
 *       - in: query
 *         name: sortOrder
 *         schema:
 *           type: string
 *           enum: [asc, desc]
 *           default: desc
 *     responses:
 *       200:
 *         description: Paginated product list.
 *   post:
 *     summary: Create a product (Admin only)
 *     tags:
 *       - Products
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - CategoryId
 *               - Name
 *               - Price
 *               - Stock
 *             properties:
 *               CategoryId:
 *                 type: integer
 *                 example: 1
 *               Name:
 *                 type: string
 *                 example: Premium Dog Food
 *               Description:
 *                 type: string
 *                 example: Nutrient-rich organic kibble for adult dogs.
 *               Price:
 *                 type: number
 *                 example: 24.99
 *               Stock:
 *                 type: integer
 *                 example: 50
 *               ImageUrl:
 *                 type: string
 *                 example: https://example.com/dogfood.png
 *     responses:
 *       201:
 *         description: Product created successfully.
 *       400:
 *         description: Validation or Category ID validation error.
 *       401:
 *         description: Unauthorized.
 *       403:
 *         description: Forbidden.
 */
export async function GET(req: NextRequest) {
  return controller.getAll(req);
}

export const POST = withAuth((req) => controller.create(req), ['ADMIN']);
