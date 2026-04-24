from fastapi import APIRouter, UploadFile, File, HTTPException
from app.db.database import execute_query
from app.services.face_pipeline import detect_faces, extract_embedding, compute_similarity, yunet
from pydantic import BaseModel
import cv2
import numpy as np
import os

router = APIRouter()

class PersonUpdate(BaseModel):
    name: str

@router.get("/persons")
def list_persons():
    query = """
        SELECT p.id, p.name, COUNT(f.id) as face_count
        FROM persons p
        LEFT JOIN faces f ON p.id = f.person_id
        GROUP BY p.id
    """
    persons = execute_query(query)
    return [{"id": p["id"], "name": p["name"], "face_count": p["face_count"]} for p in persons]

@router.get("/person/{person_id}")
def get_person_images(person_id: int):
    query = """
        SELECT i.file_path, f.bbox 
        FROM faces f
        JOIN images i ON f.image_id = i.id
        WHERE f.person_id = ?
    """
    images = execute_query(query, (person_id,))
    return [{"file_path": i["file_path"], "bbox": i["bbox"]} for i in images]

@router.put("/person/{person_id}/name")
def update_person_name(person_id: int, payload: PersonUpdate):
    person = execute_query("SELECT id FROM persons WHERE id = ?", (person_id,))
    if not person:
        raise HTTPException(status_code=404, detail="Person not found")
    execute_query("UPDATE persons SET name = ? WHERE id = ?", (payload.name, person_id), commit=True)
    return {"message": "Name updated successfully"}

@router.post("/search")
async def search_face(file: UploadFile = File(...)):
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        raise HTTPException(status_code=400, detail="Invalid image file")

    faces = detect_faces(img)
    if faces is None or len(faces) == 0:
        raise HTTPException(status_code=400, detail="No face detected in the image")
    
    face = faces[0]
    target_emb = extract_embedding(img, face)

    all_faces = execute_query("SELECT id, person_id, embedding_path FROM faces")
    
    best_match = None
    highest_sim = -1.0

    for f in all_faces:
        if os.path.exists(f["embedding_path"]):
            emb = np.load(f["embedding_path"])
            sim = compute_similarity(target_emb, emb)
            if sim > highest_sim:
                highest_sim = sim
                best_match = f

    if best_match and highest_sim > 0.5:
        return {"person_id": best_match["person_id"], "similarity": float(highest_sim)}
    
    return {"message": "No matching face found", "similarity": float(highest_sim)}
