import { PaymentController } from '@/modules/payment/payment.controller';
import { NextRequest } from 'next/server';

const controller = new PaymentController();

export const GET = (req: NextRequest) => controller.handleSuccess(req);
