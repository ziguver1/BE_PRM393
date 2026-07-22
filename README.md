# 🐾 Pet Paradise – Full-Stack Pet Shop Platform

> Hệ thống thương mại điện tử bán hàng thú cưng toàn diện, gồm backend API, ứng dụng mobile Flutter và giao diện quản trị web.

---

## 📁 Cấu trúc Monorepo

```
backend/
├── be_petshop/      # 🖥️  Backend API (Next.js 15 + Express + Socket.IO)
├── fe_pet/          # 📱  Mobile App (Flutter)
└── admin_fe/        # 🌐  Admin Dashboard (React + Vite + TailwindCSS)
```

---

## 🗂️ Tổng quan các Module

### 1. `be_petshop` — Backend API Server

| Thông tin       | Chi tiết                             |
|-----------------|--------------------------------------|
| **Framework**   | Next.js 15 + Express.js              |
| **Database**    | PostgreSQL (via Prisma ORM)          |
| **Realtime**    | Socket.IO                            |
| **Auth**        | JWT (Access + Refresh Token)         |
| **Storage**     | Cloudinary                           |
| **Payment**     | PayOS                                |
| **Push Notif.** | Firebase Cloud Messaging (FCM)       |
| **Docs**        | Swagger / OpenAPI                    |
| **Container**   | Docker + Docker Compose              |
| **Test**        | Vitest                               |

#### 📡 API Endpoints

| Nhóm            | Endpoint prefix          | Mô tả                              |
|-----------------|--------------------------|------------------------------------|
| Auth            | `/api/auth`              | Đăng ký, đăng nhập, refresh token |
| Người dùng      | `/api/users`             | Hồ sơ, cập nhật thông tin         |
| Sản phẩm        | `/api/products`          | CRUD sản phẩm, tìm kiếm, lọc      |
| Danh mục        | `/api/categories`        | Quản lý danh mục                  |
| Giỏ hàng        | `/api/cart`              | Thêm/xóa/cập nhật giỏ hàng        |
| Đơn hàng        | `/api/orders`            | Tạo, theo dõi, hủy đơn hàng      |
| Thanh toán      | `/api/payment`           | Tích hợp PayOS                    |
| Thông báo       | `/api/notifications`     | Lịch sử thông báo                 |
| Chat            | `/api/chat`              | Lịch sử hội thoại                 |
| Wishlist        | `/api/wishlist`          | Danh sách yêu thích               |
| Upload          | `/api/upload`            | Upload ảnh lên Cloudinary          |
| AI              | `/api/ai` (route)        | AI chatbot hỗ trợ                 |
| Docs            | `/api/docs`              | Swagger UI                        |

#### 🗄️ Database Schema (Prisma)

| Model               | Mô tả                                           |
|---------------------|-------------------------------------------------|
| `User`              | Người dùng (CUSTOMER / ADMIN), FCM token        |
| `Category`          | Danh mục sản phẩm                              |
| `Product`           | Sản phẩm (variants, attributes, images, filters)|
| `ProductVariant`    | Biến thể sản phẩm (kích cỡ, khối lượng...)    |
| `ProductImage`      | Ảnh sản phẩm (hỗ trợ nhiều ảnh)               |
| `ProductAttribute`  | Thuộc tính mô tả sản phẩm                      |
| `ProductFilter`     | Bộ lọc nhiều chiều (thương hiệu, độ tuổi...)   |
| `FilterGroup`       | Nhóm bộ lọc                                    |
| `FilterOption`      | Tuỳ chọn trong nhóm bộ lọc                    |
| `CartItem`          | Giỏ hàng người dùng                            |
| `Order`             | Đơn hàng (PENDING → DELIVERED → RECEIVED)     |
| `OrderDetail`       | Chi tiết đơn hàng (snapshot sản phẩm)          |
| `Notification`      | Thông báo trong app                            |
| `NotificationLog`   | Log gửi FCM (idempotency)                      |
| `Conversation`      | Hội thoại hỗ trợ (1 user – 1 conv)            |
| `Message`           | Tin nhắn trong hội thoại                       |
| `Wishlist`          | Danh sách yêu thích                            |

#### ⚙️ Cài đặt & Chạy

```bash
cd be_petshop

# 1. Cài dependencies
npm install

# 2. Tạo file môi trường
cp .env.example .env
# Điền các biến môi trường (xem bảng bên dưới)

# 3. Tạo Prisma Client (bắt buộc sau khi clone)
npx prisma generate

# 4. Đồng bộ schema lên database
#    Nếu dùng migration (khuyến nghị cho team):
npx prisma migrate deploy

#    Nếu dùng db push (prototype / cá nhân):
#    npx prisma db push

# 5. (Tuỳ chọn) Seed dữ liệu mẫu
node src/seed_categories.js
node src/seed_products.js

# 6. Chạy development (Next.js + Socket.IO concurrently)
npm run dev
```

> **⚠️ Lưu ý Prisma cho thành viên mới clone code:**
> - `npx prisma generate` → **Luôn phải chạy** để sinh ra Prisma Client (TypeScript types + query engine). Nếu bỏ qua sẽ bị lỗi `Cannot find module '@prisma/client'`.
> - `npx prisma migrate deploy` → Áp dụng **tất cả migration** trong thư mục `prisma/migrations/` vào DB. Dùng khi project có migration files.
> - `npx prisma db push` → Đẩy schema trực tiếp lên DB **không tạo migration file**. Chỉ dùng khi phát triển cá nhân / prototype, **không dùng cho production** vì mất lịch sử thay đổi schema.
>
> **Phân biệt nhanh:**
> | Tình huống | Lệnh cần chạy |
> |-----------|---------------|
> | Clone code lần đầu | `prisma generate` + `prisma migrate deploy` |
> | Schema vừa thay đổi (teammate push) | `prisma generate` + `prisma migrate deploy` |
> | Tự thêm field mới vào schema | `prisma migrate dev --name ten_thay_doi` |
> | Chỉ build/deploy production | `prisma generate` + `prisma migrate deploy` |

#### 🐳 Docker

```bash
cd be_petshop
docker-compose up --build
```

#### 🔑 Biến môi trường `be_petshop/.env`

| Biến                    | Mô tả                                       |
|-------------------------|---------------------------------------------|
| `DATABASE_URL`          | Connection string PostgreSQL                |
| `DIRECT_URL`            | Direct URL (Supabase/pooler)               |
| `JWT_ACCESS_SECRET`     | Secret key JWT access token                 |
| `JWT_REFRESH_SECRET`    | Secret key JWT refresh token                |
| `CLOUDINARY_CLOUD_NAME` | Tên cloud Cloudinary                        |
| `CLOUDINARY_API_KEY`    | API key Cloudinary                          |
| `CLOUDINARY_API_SECRET` | API secret Cloudinary                       |
| `PAYOS_CLIENT_ID`       | Client ID PayOS                             |
| `PAYOS_API_KEY`         | API key PayOS                               |
| `PAYOS_CHECKSUM_KEY`    | Checksum key PayOS                          |
| `NEXT_PUBLIC_APP_URL`   | URL công khai của server (VD: localhost:3000)|

---

### 2. `fe_pet` — Flutter Mobile App

| Thông tin       | Chi tiết                               |
|-----------------|----------------------------------------|
| **Framework**   | Flutter (Dart SDK ^3.11.5)             |
| **State Mgmt.** | Riverpod + Provider                    |
| **Routing**     | go_router                              |
| **HTTP**        | Dio                                    |
| **Auth**        | Firebase Auth + Google Sign-In + JWT   |
| **Push Notif.** | Firebase Messaging (FCM)               |
| **Realtime**    | Socket.IO Client                       |
| **Maps**        | flutter_map + latlong2                 |
| **AI Chat**     | Gemini API                             |

#### 📱 Màn hình chính

| Module            | Màn hình / Chức năng                                                              |
|-------------------|-----------------------------------------------------------------------------------|
| **Auth**          | Đăng nhập, Đăng ký, Google Sign-In                                               |
| **Home**          | Banner, danh mục nổi bật, sản phẩm nổi bật                                      |
| **Sản phẩm**      | Danh sách, chi tiết, tìm kiếm, faceted search (lọc nhiều chiều)                  |
| **Danh mục**      | Duyệt theo danh mục                                                               |
| **Giỏ hàng**      | Thêm/xóa, chọn variant, đặt hàng                                                 |
| **Đơn hàng**      | Lịch sử, theo dõi trạng thái, xem lộ trình giao hàng (bản đồ)                   |
| **Thanh toán**    | PayOS WebView                                                                     |
| **Chat**          | Hỗ trợ realtime với admin (Socket.IO)                                            |
| **AI Chat**       | Chatbot thú cưng thông minh (Gemini)                                             |
| **Wishlist**      | Yêu thích sản phẩm                                                               |
| **Profile**       | Cập nhật thông tin, avatar, đổi mật khẩu                                        |
| **Notifications** | Thông báo đẩy (FCM) + trong app                                                  |

#### 🏗️ Kiến trúc (Clean Architecture)

```
lib/
├── core/           # Theme, constants, error handling, utilities
├── data/           # Datasources, models, repositories (impl)
│   ├── datasource/ # Remote API calls (Dio)
│   ├── models/     # JSON serialization models
│   └── repository/ # Repository implementations
├── domain/         # Entities, use cases, repository interfaces
├── presentation/   # UI screens (theo từng feature)
│   ├── auth/
│   ├── cart/
│   ├── category/
│   ├── chat/
│   ├── checkout/
│   ├── favorite/
│   ├── home/
│   ├── notifications/
│   ├── order/
│   ├── product/
│   ├── profile/
│   ├── search/
│   └── wishlist/
├── providers/      # Riverpod providers
├── screens/        # Các màn hình chính (home, chat, cart, login...)
└── services/       # Auth service, notification service...
```

#### ⚙️ Cài đặt & Chạy

```bash
cd fe_pet

# 1. Cài dependencies
flutter pub get

# 2. Tạo file môi trường
# Tạo file .env với nội dung:
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta
GEMINI_MODEL=gemini-2.5-flash-lite

# 3. Cấu hình Firebase
# - Thêm google-services.json vào android/app/
# - Thêm GoogleService-Info.plist vào ios/Runner/

# 4. Chạy ứng dụng
flutter run
```

#### 🔑 Biến môi trường `fe_pet/.env`

| Biến               | Mô tả                            |
|--------------------|----------------------------------|
| `GEMINI_API_KEY`   | Google Gemini API key            |
| `GEMINI_BASE_URL`  | Base URL Gemini API              |
| `GEMINI_MODEL`     | Model Gemini sử dụng             |

---

### 3. `admin_fe` — Admin Dashboard

| Thông tin       | Chi tiết                               |
|-----------------|----------------------------------------|
| **Framework**   | React 18 + Vite                        |
| **Styling**     | TailwindCSS                            |
| **State Mgmt.** | Zustand                                |
| **HTTP**        | Axios + TanStack Query (React Query)   |
| **Realtime**    | Socket.IO Client                       |
| **Charts**      | Recharts                               |
| **Forms**       | React Hook Form + Zod                  |
| **Routing**     | React Router DOM v6                    |

#### 🖥️ Trang Admin

| Trang          | Chức năng                                              |
|----------------|--------------------------------------------------------|
| **Login**      | Xác thực admin                                         |
| **Dashboard**  | Thống kê doanh thu, đơn hàng, sản phẩm bán chạy      |
| **Sản phẩm**   | Thêm/sửa/xóa sản phẩm, quản lý variants              |
| **Đơn hàng**   | Xem và cập nhật trạng thái đơn hàng                   |
| **Người dùng** | Danh sách, xem chi tiết người dùng                    |
| **Chat**       | Hỗ trợ khách hàng realtime (Socket.IO)               |

#### ⚙️ Cài đặt & Chạy

```bash
cd admin_fe

# 1. Cài dependencies
npm install

# 2. Tạo file môi trường
cp .env.example .env
# Điền URL backend

# 3. Chạy development
npm run dev

# 4. Build production
npm run build
```

#### 🔑 Biến môi trường `admin_fe/.env`

| Biến                  | Mô tả                            |
|-----------------------|----------------------------------|
| `VITE_API_BASE_URL`   | URL backend API (VD: `/api`)     |
| `VITE_API_TIMEOUT`    | Timeout HTTP request (ms)        |

---

## 🏛️ Kiến trúc hệ thống

```
┌──────────────────────────────────────────────────────────────┐
│                        Clients                               │
│   📱 Flutter App        🌐 Admin Dashboard (React/Vite)      │
└────────────────┬───────────────────────┬────────────────────┘
                 │  HTTP / Socket.IO     │  HTTP / Socket.IO
                 ▼                       ▼
┌──────────────────────────────────────────────────────────────┐
│                   be_petshop  (Next.js 15)                   │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Next.js API Routes (/api/*)   Express Socket Server    │ │
│  │  Auth (JWT) │ REST API │ Socket.IO │ AI Route           │ │
│  └──────┬──────────────────────────────────────────────────┘ │
│         │  Prisma ORM                                         │
└─────────┼────────────────────────────────────────────────────┘
          │
   ┌──────┴──────┐   ┌────────────┐   ┌─────────────┐
   │ PostgreSQL  │   │ Cloudinary │   │   Firebase  │
   │ (Database) │   │ (Images)   │   │ (Auth / FCM)│
   └─────────────┘   └────────────┘   └─────────────┘
          │
   ┌──────┴──────┐
   │    PayOS    │
   │  (Payment) │
   └─────────────┘
```

---

## 🚀 Hướng dẫn chạy toàn bộ hệ thống

### Yêu cầu
- Node.js ≥ 20
- Flutter SDK ≥ 3.11.5
- PostgreSQL (hoặc Docker)
- Firebase project với Auth + FCM đã cấu hình

### Bước 1 — Khởi động Backend

```bash
cd be_petshop
npm install
cp .env.example .env
# Cập nhật .env với thông tin DB, JWT, Cloudinary, PayOS, Firebase
npx prisma generate
npx prisma db push
npm run dev
# → Server chạy tại http://localhost:3000
```

### Bước 2 — Khởi động Admin Dashboard

```bash
cd admin_fe
npm install
cp .env.example .env
# VITE_API_BASE_URL=http://localhost:3000/api
npm run dev
# → Admin Dashboard tại http://localhost:5173
```

### Bước 3 — Chạy Flutter App

```bash
cd fe_pet
flutter pub get
# Tạo .env với Gemini API key
# Thêm google-services.json vào android/app/
flutter run
```

---

## 🧪 Testing

### Backend

```bash
cd be_petshop
npm run test          # Chạy unit test (Vitest)
npm run test:watch    # Watch mode
```

### Flutter

```bash
cd fe_pet
flutter test
```

---

## 📋 Tính năng nổi bật

| Tính năng                         | Mô tả                                                                |
|-----------------------------------|----------------------------------------------------------------------|
| 🔐 Xác thực đa phương thức        | Email/password + Google Sign-In, JWT refresh token                  |
| 🛒 Giỏ hàng & Đặt hàng           | Hỗ trợ variants sản phẩm, snapshot thông tin khi đặt hàng          |
| 💳 Thanh toán online              | Tích hợp PayOS, WebView trong Flutter                               |
| 📦 Theo dõi đơn hàng              | Trạng thái realtime + bản đồ lộ trình giao hàng (OSRM)             |
| 💬 Chat hỗ trợ realtime           | Socket.IO, phân biệt Customer / Admin, trạng thái tin nhắn         |
| 🤖 AI Chatbot                     | Gemini API, kiến thức thú cưng tích hợp sẵn                        |
| 🔔 Push Notifications             | FCM qua Firebase Admin SDK, log gửi idempotent                      |
| 🔍 Faceted Search                 | Lọc sản phẩm nhiều chiều (thương hiệu, độ tuổi, hương vị...)       |
| 🖼️ Quản lý ảnh                    | Cloudinary, hỗ trợ nhiều ảnh mỗi sản phẩm                          |
| 📊 Dashboard quản trị             | Thống kê doanh thu, biểu đồ Recharts                                |
| 🗺️ Bản đồ giao hàng              | flutter_map + OSRM route planning                                    |
| ❤️ Wishlist                       | Lưu sản phẩm yêu thích                                             |

---

## 👥 Nhóm phát triển

Dự án được thực hiện trong khuôn khổ môn học **PRM393** — FPT University, Kỳ 8, 2026.

---

## 📄 License

This project is for educational purposes only.