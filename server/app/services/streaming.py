import os
import aiofiles
from fastapi import Request, HTTPException, status
from fastapi.responses import StreamingResponse
from app.core.logger import logger

def range_requests_response(request: Request, file_path: str, content_type: str):
    """
    Returns a StreamingResponse capable of handling HTTP Range requests
    (Requirement for modern browsers to seek/stream videos properly).
    """
    file_size = os.path.getsize(file_path)
    range_header = request.headers.get("range")
    
    headers = {
        "Accept-Ranges": "bytes",
        "Content-Type": content_type,
    }

    if not range_header:
        logger.info(f"No Range header requested for {file_path}. Streaming full file.")
        headers["Content-Length"] = str(file_size)
        return StreamingResponse(
            file_iterator(file_path, 0, file_size),
            headers=headers,
            media_type=content_type,
        )

    # Parse simple range bytes=start-end
    try:
        byte1, byte2 = 0, None
        match = range_header.replace("bytes=", "").split("-")
        if match[0]:
            byte1 = int(match[0])
        if len(match) > 1 and match[1]:
            byte2 = int(match[1])
    except ValueError as e:
        logger.warning(f"Invalid Range header requested: {range_header} for {file_path}")
        raise HTTPException(
            status_code=status.HTTP_416_REQUESTED_RANGE_NOT_SATISFIABLE,
            detail="Invalid Range header"
        )
        
    start = byte1
    end = byte2 if byte2 is not None else file_size - 1
    
    # Ensure end is within bounds
    if start >= file_size or end >= file_size:
        headers["Content-Range"] = f"bytes */{file_size}"
        logger.warning(f"Requested range {start}-{end} outside bounds for {file_path} (size: {file_size})")
        raise HTTPException(
            status_code=status.HTTP_416_REQUESTED_RANGE_NOT_SATISFIABLE,
            headers=headers,
            detail="Requested range not satisfiable"
        )
        
    chunk_size = end - start + 1
    
    headers.update({
        "Content-Length": str(chunk_size),
        "Content-Range": f"bytes {start}-{end}/{file_size}",
    })

    return StreamingResponse(
        file_iterator(file_path, start, chunk_size),
        status_code=status.HTTP_206_PARTIAL_CONTENT,
        headers=headers,
        media_type=content_type,
    )

async def file_iterator(file_path: str, offset: int, bytes_to_read: int, chunk_size: int = 1024 * 1024):
    """
    Reads a file asynchronously yielding chunks.
    """
    async with aiofiles.open(file_path, "rb") as f:
        await f.seek(offset)
        bytes_read = 0
        while bytes_read < bytes_to_read:
            # Don't read more than requested
            read_size = min(chunk_size, bytes_to_read - bytes_read)
            chunk = await f.read(read_size)
            if not chunk:
                break
            bytes_read += len(chunk)
            yield chunk
