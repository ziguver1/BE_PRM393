import { z } from 'zod';

export const updateProfileSchema = z.object({
  fullName: z.string().min(1, 'Họ và tên không được để trống').optional(),
  FullName: z.string().min(1, 'Họ và tên không được để trống').optional(),
  phoneNumber: z.string().nullable().optional(),
  Phone: z.string().nullable().optional(),
  gender: z.string().nullable().optional(),
  birthday: z.string().nullable().optional(),
  bio: z.string().nullable().optional(),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
