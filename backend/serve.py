"""
Run FastAPI with PORT from the environment (Railway, Render, Fly, etc.).
Avoids shell-specific $PORT expansion issues in some container setups.
"""
import logging
import os

import uvicorn

logger = logging.getLogger(__name__)

if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format="%(levelname)s %(name)s %(message)s",
    )
    port = int(os.environ.get("PORT", "8000"))
    logger.info("Uvicorn bind host=0.0.0.0 port=%s", port)
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=port,
        proxy_headers=True,
        forwarded_allow_ips="*",
    )
