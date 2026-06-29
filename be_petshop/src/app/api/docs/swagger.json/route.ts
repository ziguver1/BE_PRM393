import { NextResponse } from 'next/server';
import swaggerJSDoc from 'swagger-jsdoc';

const options: swaggerJSDoc.Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Pet Paradise - Pet Shop Mobile Application API',
      version: '1.0.0',
      description: 'Production-ready API endpoints documentation for Pet Paradise Pet Shop App.',
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Development Server',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
  },
  apis: ['./src/app/api/**/*.ts', './src/app/api/**/*.js'],
};

export async function GET() {
  try {
    const spec = swaggerJSDoc(options);
    return NextResponse.json(spec);
  } catch (error) {
    console.error('Swagger generation exception:', error);
    return NextResponse.json(
      { error: 'Failed to generate Swagger specifications.' },
      { status: 500 }
    );
  }
}
export const dynamic = 'force-dynamic';
