from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional
from app.api.deps import get_current_active_user, get_current_admin_user, get_db
from app.db import crud, schemas, models

router = APIRouter()

@router.post("/", response_model=schemas.OrderOut)
def place_order(order_in: schemas.OrderCreate, db: Session = Depends(get_db), current_user=Depends(get_current_active_user)):
    order = crud.create_order(db, current_user.id, order_in)
    if order_in.coupon_code:
        coupon = crud.get_coupon_by_code(db, order_in.coupon_code)
        if coupon:
            coupon.total_used += 1
            usage = models.CouponUsage(coupon_id=coupon.id, user_id=current_user.id)
            db.add(usage)
            db.commit()
    return order

@router.get("/me", response_model=list[schemas.OrderOut])
def my_orders(db: Session = Depends(get_db), current_user=Depends(get_current_active_user)):
    return db.query(models.Order).filter(models.Order.user_id == current_user.id).order_by(models.Order.created_at.desc()).all()

@router.get("/", response_model=list[schemas.OrderOut])
def list_orders(status: Optional[str] = None, db: Session = Depends(get_db), admin=Depends(get_current_admin_user)):
    return crud.get_orders(db, status)

@router.put("/{order_id}/status")
def update_status(order_id: int, status: str, db: Session = Depends(get_db), admin=Depends(get_current_admin_user)):
    order = crud.get_order(db, order_id)
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return crud.update_order_status(db, order, status)
