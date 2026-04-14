import os
from pathlib import Path
from typing import List, Dict, Any
from app.core.config import CAMERA_DIR
from app.core.logger import logger
from app.utils.media_types import get_media_type, IMAGE_EXTENSIONS, VIDEO_EXTENSIONS

def get_media_files(skip: int = 0, limit: int = 50) -> Dict[str, Any]:
    """
    Scans the camera directory for supported media files, sorts them by 
    modification date descending, and applies pagination.
    """
    if not os.path.exists(CAMERA_DIR):
        logger.error(f"Camera directory not found: {CAMERA_DIR}")
        return {"data": [], "total": 0, "error": "Camera directory not found"}

    valid_extensions = IMAGE_EXTENSIONS.union(VIDEO_EXTENSIONS)
    files_with_stats = []

    # Fast directory scanning
    try:
        with os.scandir(CAMERA_DIR) as entries:
            for entry in entries:
                if entry.is_file():
                    ext = "." + entry.name.split(".")[-1].lower() if "." in entry.name else ""
                    if ext in valid_extensions:
                        stat = entry.stat()
                        files_with_stats.append({
                            "filename": entry.name,
                            "type": get_media_type(entry.name),
                            "size": stat.st_size,
                            "mtime": stat.st_mtime,
                        })
    except Exception as e:
        logger.error(f"Error scanning directory {CAMERA_DIR}: {e}", exc_info=True)
        return {"data": [], "total": 0, "error": str(e)}

    files_with_stats.sort(key=lambda x: x["mtime"], reverse=True)
    total = len(files_with_stats)
    logger.info(f"Scanned {total} media files in {CAMERA_DIR}. Returning skip={skip}, limit={limit}")
    paginated_files = files_with_stats[skip:skip + limit]
    
    return {
        "data": paginated_files,
        "total": total,
        "skip": skip,
        "limit": limit
    }
