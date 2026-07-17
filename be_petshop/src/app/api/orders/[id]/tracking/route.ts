import { OrdersController } from '@/modules/orders/orders.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new OrdersController();

export const GET = withAuth((req, context) => controller.getTracking(req, context));
