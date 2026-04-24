import numpy as np
import os
from sklearn.cluster import DBSCAN
from app.db.database import execute_query
from app.core.logger import logger

def update_clusters():
    logger.info("Starting face clustering process...")
    faces = execute_query("SELECT id, embedding_path, person_id FROM faces")
    if not faces:
        logger.info("No faces to cluster.")
        return

    embeddings = []
    face_ids = []
    valid_faces = []
    
    for face in faces:
        path = face['embedding_path']
        if os.path.exists(path):
            emb = np.load(path)
            embeddings.append(emb)
            face_ids.append(face['id'])
            valid_faces.append(face)

    if not embeddings:
        return

    X = np.array(embeddings)
    
    dbscan = DBSCAN(eps=0.3, min_samples=2, metric='cosine', n_jobs=-1)
    labels = dbscan.fit_predict(X)
    
    existing_persons = execute_query("SELECT id FROM persons")
    existing_person_ids = set(p['id'] for p in existing_persons)
    
    cluster_to_person = {}
    
    for i, label in enumerate(labels):
        if label == -1:
            continue
        
        old_person_id = valid_faces[i]['person_id']
        
        if label not in cluster_to_person:
            if old_person_id is not None and old_person_id in existing_person_ids:
                cluster_to_person[label] = old_person_id
            else:
                new_person_id = execute_query("INSERT INTO persons (name) VALUES (?)", ("Unknown Person",), commit=True)
                cluster_to_person[label] = new_person_id
                existing_person_ids.add(new_person_id)
                
    for i, label in enumerate(labels):
        face_id = face_ids[i]
        if label == -1:
            execute_query("UPDATE faces SET person_id = NULL WHERE id = ?", (face_id,), commit=True)
        else:
            person_id = cluster_to_person[label]
            execute_query("UPDATE faces SET person_id = ? WHERE id = ?", (person_id, face_id), commit=True)
            
    logger.info("Clustering completed successfully.")
