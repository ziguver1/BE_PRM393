import { NextRequest } from 'next/server';
import { ProductsController } from '@/modules/products/products.controller';

const controller = new ProductsController();

/**
 * @openapi
 * /api/products/search:
 *   get:
 *     summary: Search products
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
 *       - in: query
 *         name: filters
 *         schema:
 *           type: string
 *           example: "1,5,8"
 *         description: Comma-separated filter option IDs for faceted search
 *     responses:
 *       200:
 *         description: Search query results.
 */
export async function GET(req: NextRequest) {
  return controller.getAll(req);
}
