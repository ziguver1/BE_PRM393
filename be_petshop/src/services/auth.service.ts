import bcrypt from 'bcryptjs';
import { UserRepository } from '../repositories/user.repository';
import { RegisterInput, LoginInput } from '../validators/auth.validator';
import { generateAccessToken, generateRefreshToken, verifyRefreshToken, TokenPayload } from '../lib/jwt';
import { AppError } from '../middleware/error.middleware';

const userRepository = new UserRepository();

export class AuthService {
  async register(input: RegisterInput) {
    const existing = await userRepository.findByEmail(input.Email);
    if (existing) {
      throw new AppError('Email address is already in use.', 409);
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(input.Password, salt);

    const user = await userRepository.create({
      FullName: input.FullName,
      Email: input.Email,
      PasswordHash: passwordHash,
      Phone: input.Phone,
      Avatar: input.Avatar,
      Role: input.Role,
    });

    const payload: TokenPayload = {
      userId: user.UserId,
      email: user.Email,
      role: user.Role,
    };

    const accessToken = generateAccessToken(payload);
    const refreshToken = generateRefreshToken(payload);

    return {
      user: {
        UserId: user.UserId,
        FullName: user.FullName,
        Email: user.Email,
        Phone: user.Phone,
        Avatar: user.Avatar,
        Role: user.Role,
      },
      accessToken,
      refreshToken,
    };
  }

  async login(input: LoginInput) {
    const user = await userRepository.findByEmail(input.Email);
    if (!user) {
      throw new AppError('Invalid email or password.', 401);
    }

    const isMatch = await bcrypt.compare(input.Password, user.PasswordHash);
    if (!isMatch) {
      throw new AppError('Invalid email or password.', 401);
    }

    const payload: TokenPayload = {
      userId: user.UserId,
      email: user.Email,
      role: user.Role,
    };

    const accessToken = generateAccessToken(payload);
    const refreshToken = generateRefreshToken(payload);

    return {
      user: {
        UserId: user.UserId,
        FullName: user.FullName,
        Email: user.Email,
        Phone: user.Phone,
        Avatar: user.Avatar,
        Role: user.Role,
      },
      accessToken,
      refreshToken,
    };
  }

  async refresh(token: string) {
    const decoded = verifyRefreshToken(token);
    if (!decoded) {
      throw new AppError('Invalid or expired refresh token.', 401);
    }

    const user = await userRepository.findById(decoded.userId);
    if (!user) {
      throw new AppError('User not found associated with this token.', 404);
    }

    const payload: TokenPayload = {
      userId: user.UserId,
      email: user.Email,
      role: user.Role,
    };

    const accessToken = generateAccessToken(payload);
    const newRefreshToken = generateRefreshToken(payload);

    return {
      accessToken,
      refreshToken: newRefreshToken,
    };
  }

  async googleLogin(input: { Email: string; FullName: string; Avatar?: string | null }) {
    let user = await userRepository.findByEmail(input.Email);

    if (!user) {
      const salt = await bcrypt.genSalt(10);
      const randomPassword = Math.random().toString(36).slice(-10) + Math.random().toString(36).slice(-10);
      const passwordHash = await bcrypt.hash(randomPassword, salt);

      user = await userRepository.create({
        FullName: input.FullName,
        Email: input.Email,
        PasswordHash: passwordHash,
        Phone: null,
        Avatar: input.Avatar || null,
        Role: 'CUSTOMER',
      });
    } else {
      if (!user.Avatar && input.Avatar) {
        await userRepository.update(user.UserId, { Avatar: input.Avatar });
        user.Avatar = input.Avatar;
      }
    }

    const payload: TokenPayload = {
      userId: user.UserId,
      email: user.Email,
      role: user.Role,
    };

    const accessToken = generateAccessToken(payload);
    const refreshToken = generateRefreshToken(payload);

    return {
      user: {
        UserId: user.UserId,
        FullName: user.FullName,
        Email: user.Email,
        Phone: user.Phone,
        Avatar: user.Avatar,
        Role: user.Role,
      },
      accessToken,
      refreshToken,
    };
  }

  async updateFcmToken(userId: number, fcmToken: string) {
    return userRepository.update(userId, { fcmToken });
  }
}
export default AuthService;
