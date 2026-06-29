import { NextResponse } from 'next/server';
import { ZodError } from 'zod';

export class AppError extends Error {
  constructor(public message: string, public status = 400) {
    super(message);
    this.name = 'AppError';
  }
}

export function handleError(error: any) {
  console.error('API Error details:', error);

  if (error instanceof AppError) {
    return NextResponse.json(
      { error: error.message },
      { status: error.status }
    );
  }

  if (error instanceof ZodError) {
    return NextResponse.json(
      {
        error: 'Validation failed',
        details: error.errors.map((e) => ({
          field: e.path.join('.'),
          message: e.message,
        })),
      },
      { status: 400 }
    );
  }

  // Handle Prisma Database Errors
  if (error.code) {
    // Unique constraint violation (e.g. email exists)
    if (error.code === 'P2002') {
      const targets = error.meta?.target || 'field';
      return NextResponse.json(
        { error: `A record with this ${targets} already exists.` },
        { status: 409 }
      );
    }
    // Record not found
    if (error.code === 'P2025') {
      return NextResponse.json(
        { error: error.meta?.cause || 'Record not found.' },
        { status: 404 }
      );
    }
  }

  return NextResponse.json(
    { error: 'An unexpected error occurred. Please try again later.' },
    { status: 500 }
  );
}
