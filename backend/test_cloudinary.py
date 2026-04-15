import sys
sys.stdout.reconfigure(line_buffering=True)

import cloudinary
import cloudinary.api
import cloudinary.uploader

cloudinary.config(
    cloud_name='dtfbkiago',
    api_key='528395456847462',
    api_secret='yVAaTrkBIbk2Db4IhsOgIxWnjy0',
    secure=True,
)

try:
    result = cloudinary.api.ping()
    print(f"Cloudinary ping: {result.get('status')}")

    # Check/create zhakas_fashion folder
    folders = cloudinary.api.root_folders()
    folder_names = [f['name'] for f in folders.get('folders', [])]
    print(f"Existing folders: {folder_names}")

    if 'zhakas_fashion' not in folder_names:
        cloudinary.api.create_folder('zhakas_fashion')
        cloudinary.api.create_folder('zhakas_fashion/products')
        cloudinary.api.create_folder('zhakas_fashion/payments')
        cloudinary.api.create_folder('zhakas_fashion/profiles')
        print("Folders created: zhakas_fashion/products, zhakas_fashion/payments, zhakas_fashion/profiles")
    else:
        print("Folder zhakas_fashion already exists")

    print("=== CLOUDINARY READY ===")
except Exception as e:
    print(f"ERROR: {e}")
