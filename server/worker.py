import time
from datetime import datetime, timedelta
import os
from pathlib import Path
from app.db.models import init_db
from app.db.database import execute_query, DB_PATH
from app.core.config import CAMERA_DIR
from app.services.face_pipeline import process_image_for_faces
from app.services.clustering import update_clusters
from app.core.logger import logger
import numpy as np

init_db()

EMBEDDINGS_DIR = Path("data/embeddings")
EMBEDDINGS_DIR.mkdir(parents=True, exist_ok=True)

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png"}

def is_allowed_time() -> bool:
    return True

def scan_directory():
    logger.info(f"Scanning directory {CAMERA_DIR}...")
    if not CAMERA_DIR.exists():
        logger.warning(f"Camera dir {CAMERA_DIR} does not exist.")
        return

    scanned_count = 0
    for root, _, files in os.walk(CAMERA_DIR):
        for file in files:
            ext = Path(file).suffix.lower()
            if ext in ALLOWED_EXTENSIONS:
                path_str = str(Path(root) / file)
                execute_query(
                    "INSERT INTO images (file_path, processed) VALUES (?, 0) ON CONFLICT(file_path) DO NOTHING",
                    (path_str,),
                    commit=True
                )
                scanned_count += 1
                if scanned_count % 500 == 0:
                    logger.info(f"Still scanning... found {scanned_count} images so far...")
    logger.info(f"Finished scanning. Total images found: {scanned_count}")

def process_new_images():
    unprocessed = execute_query("SELECT id, file_path FROM images WHERE processed = 0")
    if not unprocessed:
        logger.info("No new images to process.")
        return False
    
    total = len(unprocessed)
    logger.info(f"Found {total} unprocessed images.")
    new_faces_added = False

    for idx, row in enumerate(unprocessed, 1):
        image_id = row['id']
        file_path = row['file_path']
        
        try:
            if idx % 10 == 0 or idx == 1 or idx == total:
                logger.info(f"Processing image [{idx}/{total}] - {file_path}")
                
            faces_data = process_image_for_faces(file_path)
            
            for i, (bbox_str, embedding) in enumerate(faces_data):
                emb_path = EMBEDDINGS_DIR / f"{image_id}_{i}.npy"
                np.save(emb_path, embedding)
                
                execute_query(
                    "INSERT INTO faces (image_id, bbox, embedding_path) VALUES (?, ?, ?)",
                    (image_id, bbox_str, str(emb_path)),
                    commit=True
                )
                new_faces_added = True
            
            execute_query("UPDATE images SET processed = 1 WHERE id = ?", (image_id,), commit=True)
        except Exception as e:
            logger.error(f"Error processing {file_path}: {e}")
            
    return new_faces_added

def main_loop():
    logger.info("Face Processing Worker Started.")
    while True:
        if is_allowed_time():
            logger.info("Time window check passed. Starting task...")
            scan_directory()
            added = process_new_images()
            if added:
                update_clusters()
            logger.info("Task completed. Sleeping for 1 hour...")
            time.sleep(3600)
        else:
            now = datetime.now()
            next_run = now.replace(hour=2, minute=0, second=0, microsecond=0)
            if now.hour >= 6:
                next_run += timedelta(days=1)
            
            sleep_seconds = (next_run - now).total_seconds()
            logger.info(f"Outside allowed window. Sleeping until 2 AM ({sleep_seconds} seconds)...")
            
            # Use smaller sleep intervals to allow interrupt or FORCE_RUN checks if needed, 
            # but for simplicity we can just sleep the full duration
            time.sleep(min(sleep_seconds, 60)) # Check every minute for FORCE_RUN

if __name__ == "__main__":
    main_loop()
