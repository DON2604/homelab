import cv2
import numpy as np
from pathlib import Path
from typing import List, Tuple
from app.services.model_downloader import ensure_models_exist, YUNET_PATH, SFACE_PATH

# Initialize models
ensure_models_exist()

yunet = cv2.FaceDetectorYN.create(
    model=str(YUNET_PATH),
    config="",
    input_size=(320, 320),
    score_threshold=0.8,
    nms_threshold=0.3,
    top_k=5000
)

sface = cv2.FaceRecognizerSF.create(
    model=str(SFACE_PATH),
    config=""
)

def detect_faces(image: np.ndarray) -> List[np.ndarray]:
    height, width, _ = image.shape
    yunet.setInputSize((width, height))
    _, faces = yunet.detect(image)
    return faces if faces is not None else []

def extract_embedding(image: np.ndarray, face: np.ndarray) -> np.ndarray:
    aligned_face = sface.alignCrop(image, face)
    feature = sface.feature(aligned_face)
    return feature[0]

def process_image_for_faces(image_path: str) -> List[Tuple[str, np.ndarray]]:
    img = cv2.imread(image_path)
    if img is None:
        return []
    
    faces = detect_faces(img)
    results = []
    for face in faces:
        bbox_str = ",".join(map(str, map(int, face[:4])))
        emb = extract_embedding(img, face)
        results.append((bbox_str, emb))
    
    return results

def compute_similarity(emb1: np.ndarray, emb2: np.ndarray) -> float:
    return cv2.FaceRecognizerSF.match(sface, emb1, emb2, cv2.FaceRecognizerSF_FR_COSINE)
