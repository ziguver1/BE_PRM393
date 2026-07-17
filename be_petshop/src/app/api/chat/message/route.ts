import { ChatController } from '@/modules/chat/chat.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new ChatController();

export const POST = withAuth((req, context) => controller.sendMessage(req, context));
