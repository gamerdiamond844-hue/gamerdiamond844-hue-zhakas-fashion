from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.api.deps import get_current_admin_user, get_db
from app.db import crud, schemas, models
from app.core.cloudinary import upload_media

router = APIRouter()


@router.get("/", response_model=List[schemas.ProductOut])
def list_products(
    skip: int = 0,
    limit: int = 100,
    trending: Optional[bool] = None,
    featured: Optional[bool] = None,
    category_id: Optional[int] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
):
    query = db.query(models.Product)
    if trending is not None:
        query = query.filter(models.Product.is_trending == trending)
    if featured is not None:
        query = query.filter(models.Product.is_featured == featured)
    if category_id is not None:
        query = query.filter(models.Product.category_id == category_id)
    if search:
        query = query.filter(models.Product.title.ilike(f"%{search}%"))
    return query.order_by(models.Product.created_at.desc()).offset(skip).limit(limit).all()


@router.get("/{product_id}", response_model=schemas.ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db)):
    product = crud.get_product(db, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product


@router.post("/", response_model=schemas.ProductOut)
def add_product(product_in: schemas.ProductBase, db: Session = Depends(get_db), admin=Depends(get_current_admin_user)):
    return crud.create_product(db, product_in)


@router.put("/{product_id}", response_model=schemas.ProductOut)
def edit_product(product_id: int, product_in: schemas.ProductBase, db: Session = Depends(get_db), admin=Depends(get_current_admin_user)):
    product = crud.get_product(db, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return crud.update_product(db, product, product_in)


@router.delete("/{product_id}")
def remove_product(product_id: int, db: Session = Depends(get_db), admin=Depends(get_current_admin_user)):
    product = crud.get_product(db, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    crud.delete_product(db, product)
    return {"message": "Product deleted"}


@router.post("/upload-media")
def upload_product_media(file: UploadFile = File(...), admin=Depends(get_current_admin_user)):
    result = upload_media(file.file, folder="zhakas_fashion/products")
    return result
