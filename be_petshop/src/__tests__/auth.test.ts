import { vi, describe, it, expect, beforeEach } from 'vitest';
import { AuthService } from '../services/auth.service';
import prisma from '../lib/prisma';
import bcrypt from 'bcryptjs';

vi.mock('../lib/prisma', () => ({
  default: {
    user: {
      findUnique: vi.fn(),
      findFirst: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
  },
}));

describe('AuthService unit tests', () => {
  let authService: AuthService;

  beforeEach(() => {
    vi.clearAllMocks();
    authService = new AuthService();
  });

  describe('register', () => {
    it('should register a new user and generate token responses', async () => {
      vi.mocked(prisma.user.findUnique).mockResolvedValue(null);

      const mockUser = {
        UserId: 10,
        FullName: 'Alice Johnson',
        Email: 'alice@example.com',
        PasswordHash: 'somehashedpwd',
        Phone: '12345678',
        Avatar: null,
        fcmToken: null,
        gender: null,
        birthday: null,
        bio: null,
        Role: 'CUSTOMER' as const,
        CreatedAt: new Date(),
        UpdatedAt: new Date(),
      };
      vi.mocked(prisma.user.create).mockResolvedValue(mockUser);

      const res = await authService.register({
        FullName: 'Alice Johnson',
        Email: 'alice@example.com',
        Password: 'password123',
        Phone: '12345678',
        Avatar: null,
        Role: 'CUSTOMER',
      });

      expect(prisma.user.findUnique).toHaveBeenCalled();
      expect(prisma.user.create).toHaveBeenCalled();
      expect(res.accessToken).toBeDefined();
      expect(res.refreshToken).toBeDefined();
      expect(res.user.FullName).toBe('Alice Johnson');
    });

    it('should fail registration if email already exists', async () => {
      const mockUser = {
        UserId: 10,
        FullName: 'Alice Johnson',
        Email: 'alice@example.com',
        PasswordHash: 'somehashedpwd',
        Phone: '12345678',
        Avatar: null,
        fcmToken: null,
        gender: null,
        birthday: null,
        bio: null,
        Role: 'CUSTOMER' as const,
        CreatedAt: new Date(),
        UpdatedAt: new Date(),
      };
      vi.mocked(prisma.user.findUnique).mockResolvedValue(mockUser);

      await expect(
        authService.register({
          FullName: 'Alice Johnson',
          Email: 'alice@example.com',
          Password: 'password123',
          Phone: '12345678',
          Avatar: null,
          Role: 'CUSTOMER',
        })
      ).rejects.toThrow('Email address is already in use.');
    });
  });

  describe('login', () => {
    it('should log in with valid credentials', async () => {
      const rawPassword = 'mySecurePassword';
      const passwordHash = await bcrypt.hash(rawPassword, 8);

      const mockUser = {
        UserId: 12,
        FullName: 'Bob Smith',
        Email: 'bob@example.com',
        PasswordHash: passwordHash,
        Phone: null,
        Avatar: null,
        fcmToken: null,
        gender: null,
        birthday: null,
        bio: null,
        Role: 'CUSTOMER' as const,
        CreatedAt: new Date(),
        UpdatedAt: new Date(),
      };
      vi.mocked(prisma.user.findUnique).mockResolvedValue(mockUser);

      const res = await authService.login({
        Email: 'bob@example.com',
        Password: rawPassword,
      });

      expect(res.accessToken).toBeDefined();
      expect(res.user.Email).toBe('bob@example.com');
    });

    it('should reject login with wrong password', async () => {
      const passwordHash = await bcrypt.hash('correctPassword', 8);

      const mockUser = {
        UserId: 12,
        FullName: 'Bob Smith',
        Email: 'bob@example.com',
        PasswordHash: passwordHash,
        Phone: null,
        Avatar: null,
        fcmToken: null,
        gender: null,
        birthday: null,
        bio: null,
        Role: 'CUSTOMER' as const,
        CreatedAt: new Date(),
        UpdatedAt: new Date(),
      };
      vi.mocked(prisma.user.findUnique).mockResolvedValue(mockUser);

      await expect(
        authService.login({
          Email: 'bob@example.com',
          Password: 'wrongPassword',
        })
      ).rejects.toThrow('Invalid email or password.');
    });
  });
});
