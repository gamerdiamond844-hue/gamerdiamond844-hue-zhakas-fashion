import sys
sys.stdout.reconfigure(line_buffering=True, encoding='utf-8', errors='replace')

import urllib.request
import urllib.parse
import json

BASE = 'http://localhost:8000/api/v1'

def get(path, token=None):
    req = urllib.request.Request(f'{BASE}{path}')
    if token:
        req.add_header('Authorization', f'Bearer {token}')
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())

def post(path, data, token=None, form=False):
    if form:
        body = urllib.parse.urlencode(data).encode()
        ct = 'application/x-www-form-urlencoded'
    else:
        body = json.dumps(data).encode()
        ct = 'application/json'
    req = urllib.request.Request(f'{BASE}{path}', data=body, method='POST')
    req.add_header('Content-Type', ct)
    if token:
        req.add_header('Authorization', f'Bearer {token}')
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())

print("=" * 52)
print("   ZHAKAS FASHION -- SYSTEM HEALTH CHECK")
print("=" * 52)

# 1. Server
with urllib.request.urlopen('http://localhost:8000/') as r:
    root = json.loads(r.read())
print(f"[1] Server:      {root['status']}")

# 2. Products
products = get('/products/')
print(f"[2] Products:    {len(products)} products in DB")

# 3. Trending
trending = get('/products/?trending=true')
print(f"[3] Trending:    {len(trending)} trending products")

# 4. Admin login
login = post('/auth/login', {'username': 'admin@zhakasfashion.com', 'password': 'Admin@2026'}, form=True)
token = login['access_token']
print(f"[4] Admin Login: JWT token OK ({len(token)} chars)")

# 5. Admin dashboard
dash = get('/admin/dashboard', token=token)
print(f"[5] Dashboard:   users={dash['total_users']} orders={dash['total_orders']} revenue=Rs.{dash['revenue']}")

# 6. Coupon validate
coupon = post('/coupons/validate', {'code': 'ZHAKAS10', 'order_value': 10000}, token=token)
print(f"[6] Coupon:      ZHAKAS10 on Rs.10000 -> discount=Rs.{coupon['discount']} final=Rs.{coupon['final']}")

# 7. Cloudinary
import cloudinary, cloudinary.api
cloudinary.config(cloud_name='dtfbkiago', api_key='528395456847462', api_secret='yVAaTrkBIbk2Db4IhsOgIxWnjy0', secure=True)
ping = cloudinary.api.ping()
print(f"[7] Cloudinary:  ping={ping.get('status')} cloud=dtfbkiago")

# 8. DB tables
import sqlalchemy as sa
from app.db.session import engine
tables = sa.inspect(engine).get_table_names()
print(f"[8] DB Tables:   {', '.join(tables)}")

print("=" * 52)
print("   ALL SYSTEMS GO")
print("=" * 52)
print()
print("Admin:    admin@zhakasfashion.com / Admin@2026")
print("Coupons:  ZHAKAS10 (10% off)  |  WELCOME500 (Rs.500 flat)")
print("API Docs: http://localhost:8000/docs")
