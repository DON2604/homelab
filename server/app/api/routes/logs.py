from fastapi import APIRouter
import os

router = APIRouter()

LOG_FILE_PATH = "data/app.log"

@router.get("/")
def get_logs(limit: int = 100):
    if not os.path.exists(LOG_FILE_PATH):
        return {"logs": []}
    
    try:
        with open(LOG_FILE_PATH, "r", encoding="utf-8") as f:
            lines = f.readlines()
            return {"logs": [line.strip() for line in lines[-limit:]]}
    except Exception as e:
        return {"error": str(e), "logs": []}
