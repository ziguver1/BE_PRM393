import { NextRequest, NextResponse } from 'next/server';
import { uploadImage } from '@/lib/cloudinary';
import { handleError, AppError } from '@/middleware/error.middleware';

/**
 * @openapi
 * /api/upload:
 *   post:
 *     summary: Upload an image
 *     description: Uploads an image to Cloudinary. Returns the uploaded image secure URL. If Cloudinary credentials are not set, returns a mock image URL.
 *     tags:
 *       - Upload
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - file
 *             properties:
 *               file:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: Image uploaded successfully.
 *       400:
 *         description: No file uploaded.
 */
export async function POST(req: NextRequest) {
  try {
    const formData = await req.formData();
    const file = (formData.get('file') || formData.get('image')) as File;

    if (!file) {
      throw new AppError('No file provided. Please upload under the field name "file" or "image".', 400);
    }

    const arrayBuffer = await file.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    const imageUrl = await uploadImage(buffer);

    return NextResponse.json(
      {
        url: imageUrl,
        imageUrl: imageUrl,
      },
      { status: 200 }
    );
  } catch (error) {
    return handleError(error);
  }
}
