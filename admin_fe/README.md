# Pet Shop Admin Dashboard

Admin Dashboard frontend for Pet Shop E-commerce system.

## Tech Stack

- **React 18** - UI library
- **Vite** - Build tool
- **TypeScript** - Type safety
- **TailwindCSS** - Styling
- **React Router** - Routing
- **TanStack Query** - Data fetching
- **Axios** - HTTP client
- **Sonner** - Toast notifications
- **Lucide React** - Icons
- **Recharts** - Charts

## Architecture

This is a pure frontend application that communicates with the backend via REST API:

```
Browser → Admin Frontend → HTTP REST API → Backend (be_petshop) → Database
```

**No direct database access, no server-side logic, no ORM.**

## Project Structure

```
src/
├── api/           # Axios configuration
├── assets/        # Static assets
├── components/    # Reusable UI components
│   └── ui/       # Base UI components
├── constants/     # Constants and enums
├── contexts/      # React contexts (Auth, Theme)
├── hooks/         # Custom hooks
├── layouts/       # Layout components
├── pages/         # Page components
├── providers/     # React Query provider
├── services/      # API service layer
├── store/         # Global state (Zustand)
├── types/         # TypeScript types
├── utils/         # Utility functions
├── App.tsx        # Main app component
└── main.tsx       # Entry point
```

## Getting Started

### Prerequisites

- Node.js 18+
- npm or yarn

### Installation

```bash
npm install
```

### Environment Setup

Create a `.env` file in the root directory:

```env
VITE_API_BASE_URL=http://localhost:3000/api
VITE_API_TIMEOUT=30000
```

### Development

```bash
npm run dev
```

The dashboard will be available at `http://localhost:3001`

### Build

```bash
npm run build
```

### Preview

```bash
npm run preview
```

## Features

### Authentication
- Login via `/auth/admin/login`
- Token management with auto-refresh
- Protected routes

### Dashboard
- Revenue, orders, products, users stats
- Revenue and order charts
- Top products list

### Order Management
- Data table with filtering
- Status updates
- Payment status tracking
- Search functionality

### User Management
- User list with filtering
- Role management
- Account status (active/inactive/banned)

### Product Management
- CRUD operations
- Stock management
- Category filtering
- Image handling

### Customer Support Chat
- Conversation list
- Real-time messaging (polling)
- Message history
- Unread count

## API Integration

All API calls go through the service layer in `src/services/`:

- `auth.service.ts` - Authentication
- `order.service.ts` - Orders
- `user.service.ts` - Users
- `product.service.ts` - Products
- `chat.service.ts` - Chat
- `dashboard.service.ts` - Dashboard stats

## Styling

- **Primary Color**: Orange (#f97316)
- **Dark Mode**: Supported
- **Responsive**: Mobile-friendly
- **Design**: Modern SaaS Dashboard style

## Notes

- Lint errors are expected until dependencies are installed
- All API endpoints are configured in `src/constants/index.ts`
- Token refresh is handled automatically by Axios interceptor
- Theme preference is persisted in localStorage
