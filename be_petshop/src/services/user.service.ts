import { UserRepository } from '../repositories/user.repository';
import { AppError } from '../middleware/error.middleware';

const userRepository = new UserRepository();

export class UserService {
  async getProfile(userId: number) {
    const user = await userRepository.findProfileById(userId);
    if (!user) {
      throw new AppError('Không tìm thấy người dùng.', 404);
    }
    return user;
  }

  async updateProfile(userId: number, input: any) {
    // Check if user exists
    const user = await userRepository.findById(userId);
    if (!user) {
      throw new AppError('Không tìm thấy người dùng.', 404);
    }

    // Prepare update data mapping from either camelCase or PascalCase fields
    const data: any = {};

    const fullNameVal = input.fullName ?? input.FullName;
    if (fullNameVal !== undefined) {
      if (fullNameVal === null || fullNameVal.trim() === '') {
        throw new AppError('Họ và tên không được để trống.', 400);
      }
      data.FullName = fullNameVal;
    }

    const phoneVal = input.phoneNumber ?? input.Phone;
    if (phoneVal !== undefined) {
      data.Phone = phoneVal;
    }

    if (input.gender !== undefined) {
      data.gender = input.gender;
    }

    if (input.birthday !== undefined) {
      if (input.birthday === null) {
        data.birthday = null;
      } else {
        const date = new Date(input.birthday);
        if (isNaN(date.getTime())) {
          throw new AppError('Định dạng ngày sinh không hợp lệ.', 400);
        }
        data.birthday = date;
      }
    }

    if (input.bio !== undefined) {
      data.bio = input.bio;
    }

    if (input.avatar !== undefined) {
      data.Avatar = input.avatar;
    }

    await userRepository.update(userId, data);

    // Return the updated full profile
    return this.getProfile(userId);
  }
}

export default UserService;
