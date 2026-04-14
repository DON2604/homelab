# Homelab File Server 🏠

A powerful, self-hosted file server with remote access capabilities, lazy loading, and pagination.

## Features ✨

- **Remote Access**: Access your files from anywhere, not just local WiFi
- **Lazy Loading**: Folders load first, then files, with streaming on-demand
- **Pagination**: Handles large directories efficiently with 50 items per page
- **Search**: Full recursive search across your file system
- **File Preview & Download**: Stream files for preview or download them
- **Modern UI**: Dark theme with intuitive file browser
- **Security**: Path traversal protection to keep your files safe

## Quick Start 🚀

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure Root Directory

Edit `app/main.py` and change the `ROOT_DIR` to the directory you want to share:

```python
ROOT_DIR = Path("E:/")  # Change this to your desired directory
```

### 3. Run Locally

```bash
cd app
python main.py
```

Or with uvicorn directly:

```bash
uvicorn main:app --host 0.0.0.0 --port 5000 --reload
```

Access at: `http://localhost:5000`

### 4. View API Documentation

FastAPI provides automatic interactive API docs:
- Swagger UI: `http://localhost:5000/docs`
- ReDoc: `http://localhost:5000/redoc`

## Remote Access Setup 🌐

To access your homelab from anywhere (not just local WiFi), you have several options:

### Option 1: Port Forwarding (Simplest)

1. **Forward port 5000** on your router to your PC's local IP
2. **Get your public IP**: Visit https://whatismyipaddress.com/
3. **Access remotely**: `http://YOUR_PUBLIC_IP:5000`

⚠️ **Security Warning**: This exposes your server to the internet!

### Option 2: Cloudflare Tunnel (Recommended - Most Secure)

1. **Install Cloudflare Tunnel**:
   ```bash
   # Download from: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/
   ```

2. **Setup tunnel**:
   ```bash
   cloudflared tunnel login
   cloudflared tunnel create homelab
   cloudflared tunnel route dns homelab files.yourdomain.com
   ```

3. **Run tunnel**:
   ```bash
   cloudflared tunnel --url http://localhost:5000 run homelab
   ```

4. **Access**: `https://files.yourdomain.com`

**Benefits**:
- ✅ Free SSL/HTTPS
- ✅ No port forwarding needed
- ✅ DDoS protection
- ✅ Hidden IP address

### Option 3: Tailscale (VPN - Easy & Secure)

1. **Install Tailscale** on both PC and devices: https://tailscale.com/download
2. **Connect both to same Tailscale network**
3. **Access using Tailscale IP**: `http://100.x.x.x:5000`

**Benefits**:
- ✅ Encrypted VPN connection
- ✅ No port forwarding
- ✅ Works anywhere

### Option 4: ngrok (Quick Testing)

For temporary access:

```bash
# Install ngrok: https://ngrok.com/download
ngrok http 5000
```

You'll get a temporary URL like: `https://abc123.ngrok.io`

## Adding Authentication 🔐

For production use, add authentication! Here's a simple example with FastAPI:

### Install Dependencies

```bash
pip install python-jose[cryptography] passlib[bcrypt] python-multipart
```

### Add to main.py

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext

# Security setup
security = HTTPBearer()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
SECRET_KEY = "your-secret-key-change-this"
ALGORITHM = "HS256"

# Protect routes
@app.get('/api/browse')
async def browse(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    path: str = Query(''),
    page: int = Query(1),
    type: str = Query('all')
):
    # Verify token
    verify_token(credentials.credentials)
    # ... existing code
```

### Alternative: Basic Auth

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
import secrets

security = HTTPBasic()

def verify_credentials(credentials: HTTPBasicCredentials = Depends(security)):
    correct_username = secrets.compare_digest(credentials.username, "admin")
    correct_password = secrets.compare_digest(credentials.password, "secure_password")
    if not (correct_username and correct_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Basic"},
        )
    return credentials.username

# Protect routes
@app.get('/api/browse')
async def browse(
    username: str = Depends(verify_credentials),
    path: str = Query(''),
    page: int = Query(1),
    type: str = Query('all')
):
    # ... existing code
```

## Production Deployment 🏭

For production, FastAPI already uses uvicorn which is production-ready:

### Basic Production Setup

```bash
# Install with production extras
pip install "uvicorn[standard]"

# Run with multiple workers
uvicorn main:app --host 0.0.0.0 --port 5000 --workers 4
```

### Using Gunicorn with Uvicorn Workers (Linux/Mac)

```bash
pip install gunicorn

# Run with gunicorn managing uvicorn workers
gunicorn main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:5000
```

### Using Hypercorn (Alternative ASGI server)

```bash
pip install hypercorn

# Run
hypercorn main:app --bind 0.0.0.0:5000 --workers 4
```

## Firewall Setup 🛡️

### Windows Firewall

```powershell
# Allow inbound traffic on port 5000
New-NetFirewallRule -DisplayName "Homelab File Server" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
```

### Linux (ufw)

```bash
sudo ufw allow 5000/tcp
```

## Configuration Options ⚙️

Edit these in `app/main.py`:

```python
ROOT_DIR = Path("E:/")  # Directory to share
PAGE_SIZE = 50          # Items per page
```

## API Endpoints 📡

- `GET /` - Web interface
- `GET /api/browse?path=...&page=1&type=all` - Browse directory
- `GET /api/download?path=...&download=true` - Download/preview file
- `GET /api/search?q=...&path=...&page=1` - Search files

## Troubleshooting 🔧

### Port Already in Use

Change the port in `main.py`:
```python
app.run(host='0.0.0.0', port=8080, debug=True)  # Use 8080 instead
```

### Permission Errors

Run as administrator or ensure the user has read access to `ROOT_DIR`.

### Can't Access Remotely

1. Check firewall rules
2. Verify port forwarding
3. Confirm your PC's local IP hasn't changed
4. Try accessing via local IP first: `http://192.168.x.x:5000`

## Security Best Practices 🔒

1. **Always use authentication** in production
2. **Use HTTPS** (Cloudflare Tunnel provides this automatically)
3. **Don't expose ROOT_DIR to system files** (like C:/Windows)
4. **Keep Flask updated**: `pip install --upgrade Flask`
5. **Use environment variables** for sensitive config
6. **Enable logging** to monitor access
7. **Consider read-only mode** if you don't need uploads

## Advanced Features (Future Enhancements) 🚀

Want to add more? Consider:

- ✅ User authentication & permissions
- ✅ File upload capability
- ✅ Folder creation/deletion
- ✅ File sharing links
- ✅ Thumbnail generation for images
- ✅ Video transcoding
- ✅ Mobile app
- ✅ API rate limiting
- ✅ Audit logging

## License 📄

Free to use and modify for personal use.

## Support 💬

Having issues? Common solutions:

1. Make sure Python 3.8+ is installed
2. Install all requirements: `pip install -r requirements.txt`
3. Check the console for error messages
4. Verify ROOT_DIR exists and is readable

---

**Enjoy your personal Homelab File Server! 🎉**
