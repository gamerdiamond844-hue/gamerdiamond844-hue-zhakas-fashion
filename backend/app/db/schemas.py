from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, EmailStr, ConfigDict


class Token(BaseModel):
    access_token: str
    token_type: str


class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None
    phone: Optional[str] = None
    profile_image: Optional[str] = None


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    profile_image: Optional[str] = None


class UserOut(UserBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    is_active: bool
    is_admin: bool
    created_at: datetime


class CategoryBase(BaseModel):
    name: str
    description: Optional[str] = None


class CategoryOut(CategoryBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class ProductBase(BaseModel):
    title: str
    description: Optional[str] = None
    price: float
    discount: Optional[float] = 0.0
    stock: int
    category_id: int
    images: Optional[List[str]] = []
    video_url: Optional[str] = None
    sizes: Optional[List[str]] = []
    colors: Optional[List[str]] = []
    is_featured: bool = False
    is_trending: bool = False


class ProductOut(ProductBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class CouponBase(BaseModel):
    code: str
    discount_type: str
    discount_value: float
    expiry_date: datetime
    usage_limit: int = 0
    per_user_limit: int = 1
    applicable_to: str = "all"
    first_time_user: bool = False
    minimum_order_value: Optional[float] = 0.0
    maximum_discount: Optional[float] = None
    category: Optional[str] = None
    product_ids: Optional[List[int]] = []
    is_active: Optional[bool] = True


class CouponOut(CouponBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    is_active: bool
    total_used: int


class OrderItemCreate(BaseModel):
    product_id: int
    quantity: int
    size: Optional[str] = None
    color: Optional[str] = None
    price: float


class OrderCreate(BaseModel):
    shipping_name: str
    shipping_address: str
    shipping_phone: str
    payment_proof: Optional[str] = None
    coupon_code: Optional[str] = None
    discount_amount: Optional[float] = 0.0
    total_amount: float
    items: List[OrderItemCreate]


class OrderOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    user_id: int
    status: str
    shipping_name: str
    shipping_address: str
    shipping_phone: str
    payment_proof: Optional[str] = None
    coupon_code: Optional[str] = None
    discount_amount: float
    total_amount: float
    created_at: datetime


class WishlistOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    product_id: int
