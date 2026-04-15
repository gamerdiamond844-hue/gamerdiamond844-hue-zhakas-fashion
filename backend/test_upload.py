import sys
sys.stdout.reconfigure(line_buffering=True)

# Test via app's own cloudinary module (reads from .env)
from app.core.cloudinary import upload_media
import urllib.request

# Download a small test image
url = 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=200&q=60'
print("Downloading test image...")
with urllib.request.urlopen(url) as resp:
    image_bytes = resp.read()
print(f"Downloaded {len(image_bytes)} bytes")

# Upload to Cloudinary
import io
result = upload_media(io.BytesIO(image_bytes), folder='zhakas_fashion/products')
print(f"Upload OK!")
print(f"  URL: {result['url']}")
print(f"  Public ID: {result['public_id']}")
print("=== UPLOAD TEST PASSED ===")
