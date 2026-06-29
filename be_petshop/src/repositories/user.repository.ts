import prisma from '../lib/prisma';

export class UserRepository {
  async findByEmail(email: string) {
    return prisma.user.findUnique({
      where: { Email: email },
    });
  }

  async findById(userId: number) {
    return prisma.user.findUnique({
      where: { UserId: userId },
    });
  }

  async create(data: any) {
    return prisma.user.create({
      data,
    });
  }

  async update(userId: number, data: any) {
    return prisma.user.update({
      where: { UserId: userId },
      data,
    });
  }
}
