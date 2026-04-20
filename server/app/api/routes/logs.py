from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional, Any
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

class LogMessage(BaseModel):
    level: str
    message: str
    data: Optional[Any] = None

@router.post("/")
async def receive_log(log_msg: LogMessage):
    if log_msg.level.lower() == 'error':
        logger.error(f"Frontend Error: {log_msg.message} | Data: {log_msg.data}")
    elif log_msg.level.lower() == 'warn' or log_msg.level.lower() == 'warning':
        logger.warning(f"Frontend Warning: {log_msg.message} | Data: {log_msg.data}")
    elif log_msg.level.lower() == 'info':
        logger.info(f"Frontend Info: {log_msg.message} | Data: {log_msg.data}")
    elif log_msg.level.lower() == 'debug':
        logger.debug(f"Frontend Debug: {log_msg.message} | Data: {log_msg.data}")
    else:
        logger.info(f"Frontend Log ({log_msg.level}): {log_msg.message} | Data: {log_msg.data}")
        
    return {"status": "Logged"}
