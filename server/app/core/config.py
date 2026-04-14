import os
from pathlib import Path

# Camera Backup source directory
CAMERA_DIR = Path(r"F:\backup\Xiaomi 220333QBI\Camera")

# Ensure the cache folder for thumbnails exists inside the project tree
BASE_DIR = Path(__file__).resolve().parent.parent.parent
CACHE_DIR = BASE_DIR / "data" / "thumbnails"

# Create cache directory if it doesn't exist
os.makedirs(CACHE_DIR, exist_ok=True)
