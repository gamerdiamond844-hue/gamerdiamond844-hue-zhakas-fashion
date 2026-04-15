from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from datetime import datetime
from typing import List
from app.api.deps import get_current_admin_user, get_current_active_user, get_db
from app.db import crud, schemas, models

router = APIRouter()


class CouponValidateRequest(BaseModel):
    code: str
    order_value: float


@router.post("/validate")
def validate_coupon(
    req: CouponValidateRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_active_user),
):
    coupon = crud.get_coupon_by_code(db, req.code)
    if not coupon or not coupon.is_active:
        raise HTTPException(status_code=404, detail="Invalid coupon ❌")
    if coupon.expiry_date < datetime.utcnow():
        raise HTTPException(status_code=400, detail="Coupon expired ⌛")
    if coupon.usage_limit and coupon.total_used >= coupon.usage_limit:
        raise HTTPException(status_code=400, detail="Usage limit reached 🚫")
    if req.order_value < (coupon.minimum_order_value or 0):
        raise HTTPException(status_code=400, detail=f"Minimum order ₹{coupon.minimum_order_value:.0f} required ⚠️")
    if coupon.first_time_user and db.query(models.Order).filter(models.Order.user_id == current_user.id).count() > 0:
        raise HTTPException(status_code=400, detail="Only for first-time users ⚠️")
    user_usage = db.query(models.CouponUsage).filter(
        models.CouponUsage.coupon_id == coupon.id,
        models.CouponUsage.user_id == current_user.id,
    ).count()
    if coupon.per_user_limit and user_usage >= coupon.per_user_limit:
        raise HTTPException(status_code=400, detail="You have already used this coupon 🚫")

    discount = coupon.discount_value
    if coupon.discount_type == "percentage":
        discount = (discount / 100.0) * req.order_value
        if coupon.maximum_discount:
            discount = min(discount, coupon.maximum_discount)
    final_value = max(req.order_value - discount, 0)
    return {"discount": round(discount, 2), "final": round(final_value, 2), "coupon": coupon.code}


@router.post("/", response_model=schemas.CouponOut)
def create_coupon(coupon_in: schemas.CouponBase, db: Session = Depends(get_db), admin=Depends(get_current_admin_user)):
    existing = crud.get_coupon_by_code(db, coupon_in.code)
    if existing:
        raise HTTPException(status_code=400, detail="Coupon code already exists")
    return crud.create_coupon(db, coupon_in)


@router.get("/", response_model=List[schemas.CouponOut])
def list_coupons(db: Session = Depends(get_db), admin=Depends(get_current_admin_user)):
    return db.query(models.Coupon).order_by(models.Coupon.id.desc()).all()


@router.put("/{coupon_id}", response_model=schemas.CouponOut)
def update_coupon(coupon_id: int, coupon_in: schemas.CouponBase, db: Session = Depends(get_db), admin=Depends(get_current_admin_user)):
    coupon = db.query(models.Coupon).filter(models.Coupon.id == coupon_id).first()
    if not coupon:
        raise HTTPException(status_code=404, detail="Coupon not found")
    return crud.update_coupon(db, coupon, coupon_in)


@router.delete("/{coupon_id}")
def delete_coupon(coupon_id: int, db: Session = Depends(get_db), admin=Depends(get_current_admin_user)):
    coupon = db.query(models.Coupon).filter(models.Coupon.id == coupon_id).first()
    if not coupon:
        raise HTTPException(status_code=404, detail="Coupon not found")
    db.delete(coupon)
    db.commit()
    return {"message": "Coupon deleted"}
