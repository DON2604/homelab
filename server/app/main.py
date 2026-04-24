from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import media, logs, faces
from contextlib import asynccontextmanager
from app.db.models import init_db

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield

app = FastAPI(title="Media Dashboard Engine", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(media.router, prefix="/media", tags=["Media"])
app.include_router(logs.router, prefix="/logs", tags=["Logs"])
app.include_router(faces.router, prefix="/faces", tags=["Faces"])

@app.get("/")
def health_check():
    return {"status": "ok", "message": "Media API is running"}
