import { NextRequest, NextResponse } from 'next/server';
import { verifyAccessToken, TokenPayload } from '../lib/jwt';

export type AuthenticatedHandler = (
  req: NextRequest,
  context: { user: TokenPayload; params: any }
) => Promise<Response> | Response;

export function withAuth(handler: AuthenticatedHandler, allowedRoles?: string[]) {
  return async (req: NextRequest, props: { params: Promise<any> }) => {
    try {
      const authHeader = req.headers.get('authorization');
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return NextResponse.json(
          { error: 'Unauthorized: Missing or invalid authorization header' },
          { status: 401 }
        );
      }

      const token = authHeader.split(' ')[1];
      const decoded = verifyAccessToken(token);
      if (!decoded) {
        return NextResponse.json(
          { error: 'Unauthorized: Invalid or expired access token' },
          { status: 401 }
        );
      }

      if (allowedRoles && allowedRoles.length > 0) {
        if (!allowedRoles.includes(decoded.role)) {
          return NextResponse.json(
            { error: 'Forbidden: Insufficient privileges' },
            { status: 403 }
          );
        }
      }

      // Await params if they exist as a Promise (Next.js 15 standard)
      const resolvedParams = props?.params ? await props.params : {};

      return await handler(req, { user: decoded, params: resolvedParams });
    } catch (error: any) {
      console.error('Auth middleware exception:', error);
      return NextResponse.json(
        { error: 'Internal Server Error in authentication' },
        { status: 500 }
      );
    }
  };
}
