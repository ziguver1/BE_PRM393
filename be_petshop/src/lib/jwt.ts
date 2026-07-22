import jwt from 'jsonwebtoken';

const ACCESS_SECRET = process.env.JWT_ACCESS_SECRET || 'default-access-secret-key-12345';
const REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'default-refresh-secret-key-12345';

export interface TokenPayload {
  userId: number;
  email: string;
  role: string;
}

export function generateAccessToken(payload: TokenPayload): string {
  return jwt.sign(payload, ACCESS_SECRET, { expiresIn: '15m' });
}

export function generateRefreshToken(payload: TokenPayload): string {
  return jwt.sign(payload, REFRESH_SECRET, { expiresIn: '7d' });
}

export function verifyAccessToken(token: string): TokenPayload | null {
  try {
    return jwt.verify(token, ACCESS_SECRET) as TokenPayload;
  } catch (error) {
    return null;
  }
}

export function verifyRefreshToken(token: string): TokenPayload | null {
  try {
    return jwt.verify(token, REFRESH_SECRET) as TokenPayload;
  } catch (error) {
    return null;
  }
}

export function generateVerificationToken(email: string): string {
  return jwt.sign({ email, purpose: 'email-verification' }, ACCESS_SECRET, { expiresIn: '10m' });
}

export function verifyVerificationToken(token: string): { email: string } | null {
  try {
    const payload = jwt.verify(token, ACCESS_SECRET) as any;
    if (payload.purpose === 'email-verification' && payload.email) {
      return { email: payload.email };
    }
    return null;
  } catch (error) {
    return null;
  }
}

export function generatePasswordResetToken(email: string): string {
  return jwt.sign({ email, purpose: 'password-reset' }, ACCESS_SECRET, { expiresIn: '10m' });
}

export function verifyPasswordResetToken(token: string): { email: string } | null {
  try {
    const payload = jwt.verify(token, ACCESS_SECRET) as any;
    if (payload.purpose === 'password-reset' && payload.email) {
      return { email: payload.email };
    }
    return null;
  } catch (error) {
    return null;
  }
}
