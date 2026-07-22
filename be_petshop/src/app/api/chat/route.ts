import { NextRequest, NextResponse } from 'next/server';
import { AiController } from '../../../controllers/ai.controller';
import { handleError } from '../../../middleware/error.middleware';

const aiController = new AiController();

export async function POST(req: NextRequest) {
  try {
    const response = await aiController.handleChat(req as any);
    return response;
  } catch (error) {
    return handleError(error);
  }
}
