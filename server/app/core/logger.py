import logging
import os

def setup_logger(name: str) -> logging.Logger:
    logger = logging.getLogger(name)
    if not logger.handlers:
        logger.setLevel(logging.INFO)
        console_handler = logging.StreamHandler()
        
        # Ensure data directory exists
        os.makedirs('data', exist_ok=True)
        file_handler = logging.FileHandler('data/app.log')
        
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        console_handler.setFormatter(formatter)
        file_handler.setFormatter(formatter)
        
        logger.addHandler(console_handler)
        logger.addHandler(file_handler)
        
        # Attach to uvicorn loggers to capture terminal output
        for uvicorn_logger_name in ("uvicorn", "uvicorn.error", "uvicorn.access"):
            uvicorn_logger = logging.getLogger(uvicorn_logger_name)
            # Only add file_handler to not duplicate console logs
            if file_handler not in uvicorn_logger.handlers:
                uvicorn_logger.addHandler(file_handler)
                
    return logger

logger = setup_logger("media_app")
