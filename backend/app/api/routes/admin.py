from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional
from app.api.deps import get_db, get_current_admin_user
from app.db import crud, models, schemas

router = APIRouter()


@router.get("/dashboard")
def dashboard(db: Session = Depends(get_db), admin=Depends(get_current_admin_user)):
    return {
        "total_users": crud.count_users(db),
        "total_orders": crud.count_orders(db),
        "pending_orders": crud.count_orders(db, status="pending"),
        "revenue": crud.revenue_total(db),
    }


@router.get("/users")
def list_users(db: Session = Depends(get_db), admin=Depends(get_current_admin_user)):
    return db.query(models.User).order_by(models.User.created_at.desc()).all()


@router.put("/users/{user_id}/block")
def block_user(user_id: int, db: Session = Depends(get_db), admin=Depends(get_current_admin_user)):
    user = crud.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = False
    db.commit()
    return {"message": "User blocked"}


@router.put("/users/{user_id}/unblock")
def unblock_user(user_id: int, db: Session = Depends(get_db), admin=Depends(get_current_admin_user)):
    user = crud.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = True
    db.commit()
    return {"message": "User unblocked"}


@router.delete("/users/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db), admin=Depends(get_current_admin_user)):
    user = crud.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    db.delete(user)
    db.commit()
    return {"message": "User deleted"}


@router.get("/orders")
def admin_orders(status: Optional[str] = None, db: Session = Depends(get_db), admin=Depends(get_current_admin_user)):
    return crud.get_orders(db, status)
