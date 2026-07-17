import { ChatController } from '@/modules/chat/chat.controller';
import { withAuth } from '@/middleware/auth.middleware';

const controller = new ChatController();

export const GET = withAuth((req, context) => controller.getMessages(req, context));
