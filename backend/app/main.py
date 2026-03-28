import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.db.base import init_db, close_db
from app.api.routes import auth, accounts, signals, trades, mpesa, settings as settings_routes

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    await init_db()
    logger.info("Database initialized")

    # Telethon `client.start()` can block on interactive login — never await it in lifespan
    # or Railway health checks will time out before /health responds.
    tg_listener_task: asyncio.Task | None = None
    if settings.TELEGRAM_API_ID and settings.TELEGRAM_API_HASH:

        async def _telegram_startup():
            try:
                from app.services.telegram_listener import telegram_listener

                await telegram_listener.start()
                logger.info("Telegram listener started")
            except Exception as e:
                logger.warning("Telegram listener failed (API still up): %s", e, exc_info=True)

        tg_listener_task = asyncio.create_task(_telegram_startup())
        logger.info("Telegram listener starting in background")

    yield

    try:
        from app.services.telegram_listener import telegram_listener

        if telegram_listener.is_running:
            await telegram_listener.stop()
    except Exception:
        pass

    if tg_listener_task and not tg_listener_task.done():
        tg_listener_task.cancel()
        try:
            await tg_listener_task
        except asyncio.CancelledError:
            pass

    await close_db()
    logger.info("Database connection closed")


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.VERSION,
    description="Kenya's Smart Semi-Auto Trading API",
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    lifespan=lifespan,
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix=f"{settings.API_V1_PREFIX}/auth", tags=["Authentication"])
app.include_router(accounts.router, prefix=f"{settings.API_V1_PREFIX}/accounts", tags=["Accounts"])
app.include_router(signals.router, prefix=f"{settings.API_V1_PREFIX}/signals", tags=["Signals"])
app.include_router(trades.router, prefix=f"{settings.API_V1_PREFIX}/trades", tags=["Trades"])
app.include_router(mpesa.router, prefix=f"{settings.API_V1_PREFIX}/mpesa", tags=["M-Pesa"])
app.include_router(settings_routes.router, prefix=f"{settings.API_V1_PREFIX}/settings", tags=["Settings"])


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "name": settings.APP_NAME,
        "version": settings.VERSION,
        "status": "running"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
    )
