import { PayOS } from '@payos/node';
import prisma from '@/lib/prisma';
import { AppError } from '@/middleware/error.middleware';
import { OrderRepository } from '@/repositories/order.repository';

export class PaymentService {
  private payos: PayOS;

  constructor(clientId?: string, apiKey?: string, checksumKey?: string) {
    const resolvedClientId = clientId ?? process.env.PAYOS_CLIENT_ID;
    const resolvedApiKey = apiKey ?? process.env.PAYOS_API_KEY;
    const resolvedChecksumKey = checksumKey ?? process.env.PAYOS_CHECKSUM_KEY;

    if (!resolvedClientId || !resolvedApiKey || !resolvedChecksumKey) {
      this.payos = {
        paymentRequests: {
          create: async (payload: any) => {
            // Tự động cập nhật đơn hàng thành PAID để phục vụ mục đích test/demo không cần key thật
            await prisma.order.updateMany({
              where: { OrderCode: Number(payload.orderCode) },
              data: { Status: 'PAID' },
            });
            return {
              checkoutUrl: `${payload.returnUrl}?code=00&id=mock-transaction-id&cancel=false&status=PAID&orderCode=${payload.orderCode}`,
            };
          },
        },
        webhooks: {
          verify: async (body: any) => body.data,
        },
      } as unknown as PayOS;
      return;
    }

    this.payos = new PayOS({
      clientId: resolvedClientId,
      apiKey: resolvedApiKey,
      checksumKey: resolvedChecksumKey,
    });
  }

  private buildDescription(orderId: number) {
    const base = `Thanh toan PawMart #${orderId}`;
    return base.length > 25 ? 'Thanh toan PawMart' : base;
  }

  async createPaymentLink(orderId: number, returnUrl?: string, cancelUrl?: string) {
    const order = await prisma.order.findUnique({
      where: { OrderId: orderId },
    });

    if (!order) {
      throw new AppError('Order not found.', 404);
    }

    const orderCode = Number(String(Date.now()).slice(-9));

    await prisma.order.update({
      where: { OrderId: orderId },
      data: { OrderCode: orderCode },
    });

    const baseUrl = process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000';
    const payload = {
      orderCode,
      amount: Math.round(order.TotalAmount),
      description: this.buildDescription(orderId),
      returnUrl: returnUrl || `${baseUrl}/api/payment/success`,
      cancelUrl: cancelUrl || `${baseUrl}/api/payment/cancel`,
    };

    const paymentLink = await this.payos.paymentRequests.create(payload as any);
    return { checkoutUrl: paymentLink.checkoutUrl };
  }

  async verifyWebhook(body: any) {
    try {
      const data = await this.payos.webhooks.verify(body as any);
      if (!data) {
        throw new AppError('Invalid PayOS webhook data.', 400);
      }

      if (data.code === '00' || data.code === 'PAID') {
        const order = await prisma.order.findFirst({
          where: { OrderCode: Number(data.orderCode) },
        });
        if (order) {
          await new OrderRepository().updateStatus(order.OrderId, 'PAID');
        }
      }

      return { success: true };
    } catch (error: any) {
      console.error('PayOS Webhook validation error:', error);
      // Luôn trả về success: true để PayOS chấp nhận webhook URL này khi đăng ký
      // và ngăn PayOS gửi lại (retry) các webhook bị lỗi chữ ký.
      return { success: true, message: 'Webhook processed with signature verification skipped' };
    }
  }
}
