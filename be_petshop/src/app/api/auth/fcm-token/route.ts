import { AuthController } from '@/modules/auth/auth.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new AuthController();

export const PUT = withAuth((req, context) => controller.updateFcmToken(req, context));
