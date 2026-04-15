import sys
sys.stdout.reconfigure(line_buffering=True)

from app.db.session import SessionLocal, engine
from app.db import models, crud, schemas
from datetime import datetime, timedelta
import sqlalchemy as sa

db = SessionLocal()

# Tables
inspector = sa.inspect(engine)
print("Tables:", inspector.get_table_names())

# Admin
admin = crud.get_user_by_email(db, 'admin@zhakasfashion.com')
if not admin:
    crud.create_user(db, schemas.UserCreate(email='admin@zhakasfashion.com', password='Admin@2026', full_name='ZHAKAS Admin'), is_admin=True)
    print("Admin created")
else:
    print(f"Admin OK: {admin.email} is_admin={admin.is_admin}")

# Categories
if db.query(models.Category).count() == 0:
    for name, desc in [
        ('Sarees', 'Premium silk and designer sarees'),
        ('Lehengas', 'Bridal and festive lehengas'),
        ('New Launches', 'Latest exclusive drops'),
        ('Trending', 'Most popular picks'),
    ]:
        db.add(models.Category(name=name, description=desc))
    db.commit()
    print("Categories seeded: 4")
else:
    print(f"Categories: {db.query(models.Category).count()}")

# Products
if db.query(models.Product).count() == 0:
    items = [
        models.Product(title='Royal Silk Saree', description='Handcrafted luxury saree with gold embroidery', price=12999, discount=1200, stock=15, category_id=1, images=['https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600'], sizes=['S','M','L','XL'], colors=['Green','Gold','White'], is_trending=True, is_featured=False),
        models.Product(title='Bridal Lehenga Set', description='Premium bridal lehenga with heavy embroidery', price=24999, discount=2500, stock=8, category_id=2, images=['https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600'], sizes=['S','M','L'], colors=['Red','Pink','Maroon'], is_trending=True, is_featured=True),
        models.Product(title='Designer Banarasi Saree', description='Pure Banarasi silk with zari work', price=8999, discount=800, stock=20, category_id=1, images=['https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?w=600'], sizes=['Free Size'], colors=['Blue','Purple','Green'], is_trending=False, is_featured=True),
        models.Product(title='Festive Lehenga Choli', description='Vibrant festive lehenga with mirror work', price=15999, discount=1500, stock=12, category_id=2, images=['https://images.unsplash.com/photo-1594938298603-c8148c4b4e5b?w=600'], sizes=['S','M','L','XL'], colors=['Orange','Yellow','Pink'], is_trending=False, is_featured=True),
        models.Product(title='Embroidered Silk Saree', description='New launch - hand embroidered pure silk', price=18999, discount=2000, stock=6, category_id=3, images=['https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=600'], sizes=['Free Size'], colors=['Maroon','Gold','Cream'], is_trending=True, is_featured=True),
        models.Product(title='Georgette Party Saree', description='Lightweight georgette with sequin border', price=5999, discount=600, stock=25, category_id=4, images=['https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b?w=600'], sizes=['Free Size'], colors=['Black','Navy','Wine'], is_trending=True, is_featured=False),
    ]
    for p in items:
        db.add(p)
    db.commit()
    print(f"Products seeded: {len(items)}")
else:
    print(f"Products: {db.query(models.Product).count()}")

# Coupons
if db.query(models.Coupon).count() == 0:
    db.add(models.Coupon(code='ZHAKAS10', discount_type='percentage', discount_value=10, minimum_order_value=2000, maximum_discount=500, expiry_date=datetime.utcnow()+timedelta(days=90), usage_limit=100, per_user_limit=1, applicable_to='all', first_time_user=False, is_active=True, total_used=0))
    db.add(models.Coupon(code='WELCOME500', discount_type='flat', discount_value=500, minimum_order_value=3000, maximum_discount=None, expiry_date=datetime.utcnow()+timedelta(days=60), usage_limit=50, per_user_limit=1, applicable_to='all', first_time_user=True, is_active=True, total_used=0))
    db.commit()
    print("Coupons seeded: ZHAKAS10, WELCOME500")
else:
    print(f"Coupons: {db.query(models.Coupon).count()}")

db.close()
print("=== SEED COMPLETE ===")
