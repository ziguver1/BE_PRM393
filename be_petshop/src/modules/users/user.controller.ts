import { NextRequest, NextResponse } from 'next/server';
import { UserService } from '../../services/user.service';
import { updateProfileSchema } from '../../validators/user.validator';
import { handleError, AppError } from '../../middleware/error.middleware';
import { TokenPayload } from '../../lib/jwt';
import { uploadImage } from '../../lib/cloudinary';

const userService = new UserService();

function formatProfile(user: any) {
  return {
    id: user.UserId,
    UserId: user.UserId,
    fullName: user.FullName,
    FullName: user.FullName,
    email: user.Email,
    Email: user.Email,
    phoneNumber: user.Phone,
    Phone: user.Phone,
    avatar: user.Avatar,
    Avatar: user.Avatar,
    gender: user.gender,
    birthday: user.birthday ? user.birthday.toISOString() : null,
    bio: user.bio,
    conversationId: user.Conversation?.id || null,
    unreadSupportMessages: user.Conversation?.unreadCustomer ?? 0,
    unreadCustomer: user.Conversation?.unreadCustomer ?? 0,
    createdAt: user.CreatedAt.toISOString(),
    updatedAt: user.UpdatedAt.toISOString(),
  };
}

export class UserController {
  async getProfile(req: NextRequest, context: { user: TokenPayload }) {
    try {
      const userId = context.user.userId;
      const user = await userService.getProfile(userId);
      return NextResponse.json(formatProfile(user), { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async updateProfile(req: NextRequest, context: { user: TokenPayload }) {
    try {
      const userId = context.user.userId;
      const body = await req.json();
      const validated = updateProfileSchema.parse(body);

      const user = await userService.updateProfile(userId, validated);
      return NextResponse.json(formatProfile(user), { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }

  async uploadAvatar(req: NextRequest, context: { user: TokenPayload }) {
    try {
      const userId = context.user.userId;
      const formData = await req.formData();
      const file = (formData.get('file') || formData.get('image')) as File;

      if (!file) {
        throw new AppError('Không tìm thấy tệp ảnh tải lên. Vui lòng gửi dưới dạng "file" hoặc "image".', 400);
      }

      if (!file.type.startsWith('image/')) {
        throw new AppError('Chỉ cho phép tải lên tệp hình ảnh.', 400);
      }

      if (file.size > 5 * 1024 * 1024) {
        throw new AppError('Dung lượng ảnh vượt quá giới hạn cho phép (tối đa 5MB).', 400);
      }

      const arrayBuffer = await file.arrayBuffer();
      const buffer = Buffer.from(arrayBuffer);
      
      // Reuse the existing Cloudinary configuration and service
      const imageUrl = await uploadImage(buffer, 'avatars');

      const user = await userService.updateProfile(userId, { avatar: imageUrl });
      return NextResponse.json(formatProfile(user), { status: 200 });
    } catch (error) {
      return handleError(error);
    }
  }
}

export default UserController;
