# ZHAKAS FASHION — Complete Setup Guide

## Project Structure

```
zhakas fashion/
├── backend/          FastAPI backend (Python)
│   ├── app/
│   │   ├── api/      Routes: auth, users, products, orders, coupons, admin
│   │   ├── core/     Config, security, cloudinary, logging
│   │   └── db/       Models, schemas, CRUD, session
│   ├── sql/schema.sql
│   ├── .env.example
│   └── requirements.txt
├── frontend/         Flutter app (Android)
│   └── lib/
│       ├── models/   Product, Order, CartItem, Coupon, User
│       ├── providers/ CartProvider, ProductProvider, WishlistProvider
│       ├── screens/  All customer + admin screens
│       ├── services/ ApiService, AuthService
│       ├── theme.dart
│       └── routes.dart
└── docs/setup.md
```

---

## 1. Backend Setup (FastAPI + Neon PostgreSQL)

### Step 1 — Configure environment

```powershell
cd "c:\Users\MAYUR\Downloads\zhakas fashion\backend"
copy .env.example .env
```

Edit `.env`:

```env
DATABASE_URL=postgresql+psycopg2://<user>:<password>@<neon-host>/<dbname>?sslmode=require
SECRET_KEY=your-very-secure-random-secret-key-min-32-chars
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
ADMIN_SECRET_KEY=zhaKasAdmin2026
```

> Get Neon DB URL from: https://neon.tech → Project → Connection string (psycopg2 format)
> Get Cloudinary credentials from: https://cloudinary.com → Dashboard

### Step 2 — Install dependencies

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### Step 3 — Initialize database schema

```powershell
psql "<your_neon_connection_string>" -f sql/schema.sql
```

Or use Neon SQL Editor and paste contents of `sql/schema.sql`.

### Step 4 — Create admin user (run once)

```python
# Run in Python shell inside venv
from app.db.session import SessionLocal
from app.db import crud, schemas

db = SessionLocal()
crud.create_user(db, schemas.UserCreate(
    email="admin@zhakasfashion.com",
    password="Admin@2026",
    full_name="ZHAKAS Admin"
), is_admin=True)
db.close()
```

### Step 5 — Run backend

```powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API docs: http://127.0.0.1:8000/docs

---

## 2. Frontend Setup (Flutter)

### Step 1 — Install Flutter SDK

Download from https://flutter.dev/docs/get-started/install/windows

Verify:
```powershell
flutter doctor
```

### Step 2 — Configure API base URL

Edit `frontend/lib/services/api_service.dart`:

```dart
// For Android emulator (default):
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

// For physical device (use your PC's local IP):
static const String baseUrl = 'http://192.168.x.x:8000/api/v1';

// For production:
static const String baseUrl = 'https://api.zhakasfashion.com/api/v1';
```

### Step 3 — Get dependencies

```powershell
cd "c:\Users\MAYUR\Downloads\zhakas fashion\frontend"
flutter pub get
```

### Step 4 — Run on emulator/device

```powershell
flutter run
```

### Step 5 — Build release APK

```powershell
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

---

## 3. Admin Panel Access

1. Open the app
2. On the Login screen, tap **"Admin Access →"**
3. Enter admin email + password (created in Step 4 above)
4. Access full admin dashboard

---

## 4. API Endpoints Reference

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /auth/signup | — | Register user |
| POST | /auth/login | — | Login (returns JWT) |
| GET | /users/me | User | Get profile |
| PUT | /users/me | User | Update profile |
| GET | /users/wishlist | User | Get wishlist |
| POST | /users/wishlist/{id} | User | Add to wishlist |
| DELETE | /users/wishlist/{id} | User | Remove from wishlist |
| GET | /products/ | — | List products (supports ?trending=true&featured=true&search=) |
| POST | /products/ | Admin | Add product |
| PUT | /products/{id} | Admin | Edit product |
| DELETE | /products/{id} | Admin | Delete product |
| POST | /products/upload-media | Admin | Upload image to Cloudinary |
| POST | /orders/ | User | Place order |
| GET | /orders/me | User | My orders |
| GET | /orders/ | Admin | All orders (supports ?status=pending) |
| PUT | /orders/{id}/status | Admin | Approve/reject order |
| POST | /coupons/validate | User | Validate coupon |
| POST | /coupons/ | Admin | Create coupon |
| GET | /coupons/ | Admin | List coupons |
| PUT | /coupons/{id} | Admin | Update coupon |
| DELETE | /coupons/{id} | Admin | Delete coupon |
| GET | /admin/dashboard | Admin | Stats overview |
| GET | /admin/users | Admin | All users |
| PUT | /admin/users/{id}/block | Admin | Block user |
| PUT | /admin/users/{id}/unblock | Admin | Unblock user |
| DELETE | /admin/users/{id} | Admin | Delete user |

---

## 5. Features Implemented

### Customer App
- ✅ Animated splash screen with auth state detection
- ✅ Login / Signup with form validation
- ✅ Home screen with shimmer loading, product sections, search
- ✅ Product detail with image gallery, size/color selection
- ✅ Cart with quantity management
- ✅ Coupon validation with real-time discount calculation
- ✅ Order placement with QR payment + screenshot upload
- ✅ Wishlist with add/remove
- ✅ Profile with order history and edit

### Admin Panel
- ✅ Secure admin login (JWT + is_admin check)
- ✅ Dashboard with live stats + bar chart
- ✅ Product CRUD with Cloudinary image upload
- ✅ Order management with approve/reject + payment proof viewer
- ✅ Coupon engine: create/edit/delete, toggle active, expiry, per-user limits
- ✅ User management with block/unblock

### Backend
- ✅ FastAPI with JWT authentication
- ✅ bcrypt password hashing
- ✅ Neon PostgreSQL (SQLAlchemy ORM)
- ✅ Cloudinary media upload
- ✅ Coupon validation with per-user tracking
- ✅ CORS configured
- ✅ Structured logging

---

## 6. Production Deployment

### Backend (VPS / Railway / Render)

```bash
# Install production server
pip install gunicorn

# Run with Gunicorn + Uvicorn workers
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

Nginx config (reverse proxy):
```nginx
server {
    listen 80;
    server_name api.zhakasfashion.com;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Security Checklist
- [ ] Set strong `SECRET_KEY` (32+ random chars)
- [ ] Use HTTPS in production
- [ ] Set `allow_origins` to your domain only in CORS
- [ ] Store `.env` securely, never commit to git
- [ ] Enable Neon connection pooling for scale
