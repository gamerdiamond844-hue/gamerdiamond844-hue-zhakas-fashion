from datetime import datetime
from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, JSON, String, Text
from sqlalchemy.orm import relationship
from app.db.session import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    full_name = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    hashed_password = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    is_admin = Column(Boolean, default=False)
    profile_image = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    orders = relationship("Order", back_populates="user")
    wishlist = relationship("Wishlist", back_populates="user")

class Category(Base):
    __tablename__ = "categories"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, nullable=False)
    description = Column(String, nullable=True)
    products = relationship("Product", back_populates="category")

class Product(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    price = Column(Float, nullable=False)
    discount = Column(Float, default=0.0)
    stock = Column(Integer, default=0)
    category_id = Column(Integer, ForeignKey("categories.id"))
    images = Column(JSON, default=[])
    video_url = Column(String, nullable=True)
    sizes = Column(JSON, default=[])
    colors = Column(JSON, default=[])
    is_featured = Column(Boolean, default=False)
    is_trending = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    category = relationship("Category", back_populates="products")
    order_items = relationship("OrderItem", back_populates="product")

class Coupon(Base):
    __tablename__ = "coupons"
    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, nullable=False)
    discount_type = Column(String, nullable=False)
    discount_value = Column(Float, nullable=False)
    minimum_order_value = Column(Float, default=0.0)
    maximum_discount = Column(Float, nullable=True)
    expiry_date = Column(DateTime, nullable=False)
    usage_limit = Column(Integer, default=0)
    per_user_limit = Column(Integer, default=1)
    applicable_to = Column(String, default="all")
    category = Column(String, nullable=True)
    product_ids = Column(JSON, default=[])
    first_time_user = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    total_used = Column(Integer, default=0)

class Order(Base):
    __tablename__ = "orders"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    status = Column(String, default="pending")
    shipping_name = Column(String, nullable=False)
    shipping_address = Column(Text, nullable=False)
    shipping_phone = Column(String, nullable=False)
    payment_proof = Column(String, nullable=True)
    coupon_code = Column(String, nullable=True)
    discount_amount = Column(Float, default=0.0)
    total_amount = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    user = relationship("User", back_populates="orders")
    items = relationship("OrderItem", back_populates="order")

class OrderItem(Base):
    __tablename__ = "order_items"
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    product_id = Column(Integer, ForeignKey("products.id"))
    quantity = Column(Integer, nullable=False)
    size = Column(String, nullable=True)
    color = Column(String, nullable=True)
    price = Column(Float, nullable=False)
    product = relationship("Product", back_populates="order_items")
    order = relationship("Order", back_populates="items")

class CouponUsage(Base):
    __tablename__ = "coupon_usages"
    id = Column(Integer, primary_key=True, index=True)
    coupon_id = Column(Integer, ForeignKey("coupons.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    used_at = Column(DateTime, default=datetime.utcnow)

class Wishlist(Base):
    __tablename__ = "wishlists"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    product_id = Column(Integer, ForeignKey("products.id"))
    created_at = Column(DateTime, default=datetime.utcnow)
    user = relationship("User", back_populates="wishlist")
    product = relationship("Product")
