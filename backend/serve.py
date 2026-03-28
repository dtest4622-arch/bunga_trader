"""
Run FastAPI with PORT from the environment (Railway, Render, Fly, etc.).
Avoids shell-specific $PORT expansion issues in some container setups.
"""
import os

import uvicorn

if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8000"))
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=port,
        proxy_headers=True,
        forwarded_allow_ips="*",
    )
