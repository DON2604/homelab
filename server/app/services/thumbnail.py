import os
import cv2
from PIL import Image
from pathlib import Path
from app.core.config import CACHE_DIR
from app.core.logger import logger
from app.utils.media_types import get_media_type

def get_thumbnail(original_filepath: str, filename: str) -> str:
    """
    Returns the path to a generated thumbnail for the given media file.
    Generates it via PIL/OpenCV if missing.
    """
    # Force extension to .jpg for thumbnails
    thumb_filename = f"{filename}_thumb.jpg"
    thumb_path = CACHE_DIR / thumb_filename

    # If it already exists, return early
    if thumb_path.exists():
        return str(thumb_path)
    
    logger.info(f"Generating new thumbnail for {filename}")
    media_type = get_media_type(filename)
    
    try:
        if media_type == "image":
            _generate_image_thumbnail(original_filepath, str(thumb_path))
        elif media_type == "video":
            _generate_video_thumbnail(original_filepath, str(thumb_path))
        else:
            logger.warning(f"Unsupported media type for thumbnail generation: {filename}")
            return None # Unsupported
    except Exception as e:
        logger.error(f"Thumbnail error for {filename}: {e}", exc_info=True)
        return None

    if thumb_path.exists():
        return str(thumb_path)
    return None

def _generate_image_thumbnail(src_path: str, dst_path: str, size: tuple = (256, 256)):
    with Image.open(src_path) as img:
        # Convert to RGB to ensure jpeg support (e.g. for png/gif with alpha)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        img.thumbnail(size)
        img.save(dst_path, "JPEG", quality=85)

def _generate_video_thumbnail(src_path: str, dst_path: str):
    cap = cv2.VideoCapture(src_path)
    try:
        # Read the first frame
        ret, frame = cap.read()
        if ret:
            # Resize for speed/size
            frame = cv2.resize(frame, (256, 256), interpolation=cv2.INTER_AREA)
            cv2.imwrite(dst_path, frame)
    finally:
        cap.release()
