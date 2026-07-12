const swaggerJSDoc = require('swagger-jsdoc');
const path = require('path');

const options = {
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
  },
  apis: [
    './src/app/api/**/*.ts',
    './src/app/api/**/*.js'
  ],
};

try {
  const spec = swaggerJSDoc(options);
  console.log(JSON.stringify(spec, null, 2));
} catch (error) {
  console.error('Error generating swagger:', error);
}
