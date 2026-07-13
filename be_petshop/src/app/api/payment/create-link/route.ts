import { PaymentController } from '@/modules/payment/payment.controller';

const controller = new PaymentController();

export const POST = (req: Request) => controller.createLink(req as any);
