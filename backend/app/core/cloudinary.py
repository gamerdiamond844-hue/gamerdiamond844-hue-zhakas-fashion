import cloudinary
import cloudinary.uploader
from app.core.config import settings

cloudinary.config(
    cloud_name=settings.CLOUDINARY_CLOUD_NAME,
    api_key=settings.CLOUDINARY_API_KEY,
    api_secret=settings.CLOUDINARY_API_SECRET,
    secure=True,
)


def upload_media(file_data, folder: str = "zhakas_fashion") -> dict:
    result = cloudinary.uploader.upload(file_data, folder=folder)
    return {"url": result.get("secure_url"), "public_id": result.get("public_id")}
