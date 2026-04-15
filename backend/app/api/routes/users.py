from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.api.deps import get_current_active_user, get_db
from app.db import crud, schemas, models

router = APIRouter()

@router.get("/me", response_model=schemas.UserOut)
def read_current_user(current_user: schemas.UserOut = Depends(get_current_active_user)):
    return current_user

@router.put("/me", response_model=schemas.UserOut)
def update_current_user(user_in: schemas.UserUpdate, db: Session = Depends(get_db), current_user=Depends(get_current_active_user)):
    db_user = crud.get_user(db, current_user.id)
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    return crud.update_user(db, db_user, user_in)

@router.post("/profile-photo")
def upload_profile_photo(url: str, db: Session = Depends(get_db), current_user=Depends(get_current_active_user)):
    user = crud.get_user(db, current_user.id)
    user.profile_image = url
    db.commit()
    return {"message": "Profile image updated."}

@router.get("/wishlist", response_model=List[schemas.WishlistOut])
def get_wishlist(db: Session = Depends(get_db), current_user=Depends(get_current_active_user)):
    return db.query(models.Wishlist).filter(models.Wishlist.user_id == current_user.id).all()

@router.post("/wishlist/{product_id}")
def add_to_wishlist(product_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_active_user)):
    existing = db.query(models.Wishlist).filter(models.Wishlist.user_id == current_user.id, models.Wishlist.product_id == product_id).first()
    if existing:
        return {"message": "Already in wishlist"}
    db.add(models.Wishlist(user_id=current_user.id, product_id=product_id))
    db.commit()
    return {"message": "Added to wishlist"}

@router.delete("/wishlist/{product_id}")
def remove_from_wishlist(product_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_active_user)):
    item = db.query(models.Wishlist).filter(models.Wishlist.user_id == current_user.id, models.Wishlist.product_id == product_id).first()
    if item:
        db.delete(item)
        db.commit()
    return {"message": "Removed from wishlist"}
