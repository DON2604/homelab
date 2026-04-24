from app.db.database import DB_PATH
import sqlite3

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    cursor.execute('''
    CREATE TABLE IF NOT EXISTS persons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
    )
    ''')

    cursor.execute('''
    CREATE TABLE IF NOT EXISTS images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path TEXT UNIQUE NOT NULL,
        processed BOOLEAN NOT NULL DEFAULT 0,
        added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ''')

    cursor.execute('''
    CREATE TABLE IF NOT EXISTS faces (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_id INTEGER NOT NULL,
        person_id INTEGER,
        bbox TEXT NOT NULL,
        embedding_path TEXT NOT NULL,
        FOREIGN KEY (image_id) REFERENCES images (id),
        FOREIGN KEY (person_id) REFERENCES persons (id)
    )
    ''')
    
    conn.commit()
    conn.close()
