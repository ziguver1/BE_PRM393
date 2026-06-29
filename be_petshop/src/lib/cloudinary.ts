import { v2 as cloudinary } from 'cloudinary';

const isCloudinaryConfigured =
  !!(process.env.CLOUDINARY_CLOUD_NAME &&
  process.env.CLOUDINARY_API_KEY &&
  process.env.CLOUDINARY_API_SECRET);

if (isCloudinaryConfigured) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
  });
}

export async function uploadImage(fileBuffer: Buffer, folder = 'petshop'): Promise<string> {
  if (!isCloudinaryConfigured) {
    console.warn('Cloudinary environment variables are missing. Using mock upload fallback.');
    // Simulate brief delay
    await new Promise((resolve) => setTimeout(resolve, 100));
    return `https://res.cloudinary.com/demo/image/upload/v1234567890/petshop_mock_${Date.now()}.png`;
  }

  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      { folder },
      (error, result) => {
        if (error || !result) {
          return reject(error || new Error('Cloudinary upload returned no result'));
        }
        resolve(result.secure_url);
      }
    );
    uploadStream.end(fileBuffer);
  });
}
