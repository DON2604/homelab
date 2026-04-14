# Supported media extensions

IMAGE_EXTENSIONS = {
    ".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".tiff"
}

VIDEO_EXTENSIONS = {
    ".mp4", ".mov", ".avi", ".mkv", ".webm", ".m4v"
}

def get_media_type(filename: str) -> str:
    """Returns 'image', 'video', or 'unknown' based on the file extension."""
    ext = "." + filename.split(".")[-1].lower() if "." in filename else ""
    
    if ext in IMAGE_EXTENSIONS:
        return "image"
    elif ext in VIDEO_EXTENSIONS:
        return "video"
    else:
        return "unknown"
