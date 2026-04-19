import os
from fastapi import APIRouter, Depends, Query, HTTPException, Request
from fastapi.responses import FileResponse, Response
from typing import Optional

from app.core.config import CAMERA_DIR
from app.core.logger import logger
from app.services.scanner import get_media_files
from app.services.thumbnail import get_thumbnail
from app.services.streaming import range_requests_response
from app.utils.media_types import get_media_type

router = APIRouter()

@router.get("/")
def list_media(
    skip: int = Query(0, ge=0), 
    limit: int = Query(50, ge=1, le=100),
    filter_type: Optional[str] = Query(None, description="Filter by media type (e.g. 'image' or 'video')")
):
    """Validates files from the directory via chunks and optional type filtering."""
    return get_media_files(skip=skip, limit=limit, filter_type=filter_type)

@router.get("/{filename}/thumbnail")
def media_thumbnail(filename: str):
    logger.info(f"Thumbnail requested for {filename}")
    file_path = os.path.join(CAMERA_DIR, filename)
    if not os.path.exists(file_path):
        logger.warning(f"Thumbnail failed: file not found {file_path}")
        raise HTTPException(status_code=404, detail="File not found")

    thumb_path = get_thumbnail(file_path, filename)
    if thumb_path:
        return FileResponse(thumb_path, media_type="image/jpeg")
    
    raise HTTPException(status_code=500, detail="Could not generate thumbnail")

@router.get("/{filename}/full")
def media_full(filename: str):
    """Returns the full quality image/video without streaming headers."""
    logger.info(f"Full media requested for {filename}")
    file_path = os.path.join(CAMERA_DIR, filename)
    if not os.path.exists(file_path):
        logger.warning(f"Full media failed: file not found {file_path}")
        raise HTTPException(status_code=404, detail="File not found")
        
    return FileResponse(file_path)

@router.get("/{filename}/stream")
def stream_video(request: Request, filename: str):
    """Streams a video file efficiently handling seeking chunk range requests."""
    logger.info(f"Video stream requested for {filename}")
    file_path = os.path.join(CAMERA_DIR, filename)
    if not os.path.exists(file_path):
        logger.warning(f"Video stream failed: file not found {file_path}")
        raise HTTPException(status_code=404, detail="File not found")

    media_type = get_media_type(filename)
    if media_type != "video":
        logger.warning(f"Video stream failed: NOT a video file {filename}")
        raise HTTPException(status_code=400, detail="Not a video file")
        
    # Standard mp4 content type, though ideally this would map exact extension types
    content_type = "video/mp4" 
    
    return range_requests_response(request, file_path, content_type)
