import { PrismaClient } from '@prisma/client';

const globalForPrisma = global as unknown as { prisma: PrismaClient };

function withSafeConnectionParams(url?: string): string | undefined {
  if (!url) return undefined;

  try {
    const parsed = new URL(url);
    const isSupabasePooler = parsed.hostname.includes('pooler.supabase.com');

    // Supabase session poolers can hit low connection ceilings in local dev.
    // Cap Prisma pool size unless explicitly configured in DATABASE_URL.
    if (isSupabasePooler && !parsed.searchParams.has('connection_limit')) {
      parsed.searchParams.set('connection_limit', '1');
      if (!parsed.searchParams.has('pool_timeout')) {
        parsed.searchParams.set('pool_timeout', '20');
      }
      return parsed.toString();
    }

    return url;
  } catch (_) {
    // If URL parsing fails, fall back to the original value.
    return url;
  }
}

export const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    datasources: {
      db: {
        url: withSafeConnectionParams(process.env.DATABASE_URL),
      },
    },
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
  });

// Always keep a single Prisma instance in-process to avoid connection storms.
if (!globalForPrisma.prisma) {
  globalForPrisma.prisma = prisma;
}
export default prisma;
