import { z } from 'zod';

export const registerSchema = z.object({
  FullName: z.string().min(2, 'Full name must be at least 2 characters'),
  Email: z.string().email('Invalid email address'),
  Password: z.string().min(6, 'Password must be at least 6 characters'),
  Phone: z.string().optional().nullable(),
  Avatar: z.string().url('Invalid avatar URL').optional().nullable(),
  Role: z.enum(['ADMIN', 'CUSTOMER']).default('CUSTOMER'),
});

export const loginSchema = z.object({
  Email: z.string().email('Invalid email address'),
  Password: z.string().min(1, 'Password is required'),
});

export const refreshSchema = z.object({
  RefreshToken: z.string().min(1, 'Refresh token is required'),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type RefreshInput = z.infer<typeof refreshSchema>;
