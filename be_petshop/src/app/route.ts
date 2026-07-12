import { redirect } from 'next/navigation';

export async function GET() {
  redirect('/api/docs');
}

export const dynamic = 'force-dynamic';
