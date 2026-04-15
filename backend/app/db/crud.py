from datetime import datetime
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.db import models, schemas
from app.core.security import get_password_hash

# User operations

def get_user_by_email(db: Session, email: str) -> Optional[models.User]:
    return db.query(models.User).filter(models.User.email == email).first()


def get_user(db: Session, user_id: int) -> Optional[models.User]:
    return db.query(models.User).filter(models.User.id == user_id).first()


def create_user(db: Session, user_in: schemas.UserCreate, is_admin: bool = False) -> models.User:
    user = models.User(
        email=user_in.email,
        full_name=user_in.full_name,
        phone=user_in.phone,
        hashed_password=get_password_hash(user_in.password),
        is_admin=is_admin,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def update_user(db: Session, user: models.User, user_in: schemas.UserUpdate) -> models.User:
    for field, value in user_in.dict(exclude_unset=True).items():
        setattr(user, field, value)
    db.commit()
    db.refresh(user)
    return user


def deactivate_user(db: Session, user: models.User) -> models.User:
    user.is_active = False
    db.commit()
    return user

# Product operations

def get_products(db: Session, skip: int = 0, limit: int = 50) -> List[models.Product]:
    return db.query(models.Product).offset(skip).limit(limit).all()


def get_product(db: Session, product_id: int) -> Optional[models.Product]:
    return db.query(models.Product).filter(models.Product.id == product_id).first()


def create_product(db: Session, product_in: schemas.ProductBase) -> models.Product:
    product = models.Product(**product_in.dict())
    db.add(product)
    db.commit()
    db.refresh(product)
    return product


def update_product(db: Session, product: models.Product, product_in: schemas.ProductBase) -> models.Product:
    for field, value in product_in.dict(exclude_unset=True).items():
        setattr(product, field, value)
    db.commit()
    db.refresh(product)
    return product


def delete_product(db: Session, product: models.Product):
    db.delete(product)
    db.commit()

# Coupon operations

def get_coupon_by_code(db: Session, code: str) -> Optional[models.Coupon]:
    return db.query(models.Coupon).filter(func.lower(models.Coupon.code) == code.lower()).first()


def create_coupon(db: Session, coupon_in: schemas.CouponBase) -> models.Coupon:
    coupon = models.Coupon(**coupon_in.dict())
    db.add(coupon)
    db.commit()
    db.refresh(coupon)
    return coupon


def update_coupon(db: Session, coupon: models.Coupon, coupon_in: schemas.CouponBase) -> models.Coupon:
    for field, value in coupon_in.dict(exclude_unset=True).items():
        setattr(coupon, field, value)
    db.commit()
    db.refresh(coupon)
    return coupon

# Order operations

def create_order(db: Session, user_id: int, order_in: schemas.OrderCreate) -> models.Order:
    order = models.Order(
        user_id=user_id,
        shipping_name=order_in.shipping_name,
        shipping_address=order_in.shipping_address,
        shipping_phone=order_in.shipping_phone,
        payment_proof=order_in.payment_proof,
        coupon_code=order_in.coupon_code,
        discount_amount=order_in.discount_amount,
        total_amount=order_in.total_amount,
        status="pending",
    )
    db.add(order)
    db.commit()
    db.refresh(order)
    for item in order_in.items:
        order_item = models.OrderItem(
            order_id=order.id,
            product_id=item.product_id,
            quantity=item.quantity,
            size=item.size,
            color=item.color,
            price=item.price,
        )
        db.add(order_item)
    db.commit()
    db.refresh(order)
    return order


def get_orders(db: Session, status: Optional[str] = None) -> List[models.Order]:
    query = db.query(models.Order)
    if status:
        query = query.filter(models.Order.status == status)
    return query.order_by(models.Order.created_at.desc()).all()


def get_order(db: Session, order_id: int) -> Optional[models.Order]:
    return db.query(models.Order).filter(models.Order.id == order_id).first()


def update_order_status(db: Session, order: models.Order, status: str) -> models.Order:
    order.status = status
    db.commit()
    db.refresh(order)
    return order

# Analytics

def count_users(db: Session) -> int:
    return db.query(models.User).filter(models.User.is_active == True).count()


def count_orders(db: Session, status: Optional[str] = None) -> int:
    query = db.query(models.Order)
    if status:
        query = query.filter(models.Order.status == status)
    return query.count()


def revenue_total(db: Session) -> float:
    total = db.query(func.sum(models.Order.total_amount - models.Order.discount_amount)).scalar()
    return float(total or 0.0)
