from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
from app.core.config import settings
import ssl
import logging

logger = logging.getLogger(__name__)

# Lazy-loaded engine
_engine = None
_AsyncSessionLocal = None


def _get_engine():
    """Get or create the async engine."""
    global _engine
    if _engine is None:
        if not settings.DATABASE_URL or settings.DATABASE_URL.strip() == "":
            raise RuntimeError(
                "DATABASE_URL is not configured. Please set the DATABASE_URL environment variable. "
                "For Railway, ensure the Postgres database plugin is connected to this service."
            )
        
        logger.info(f"Initializing database connection...")
        
        _connect_args: dict = {}
        if settings.DATABASE_SSL_REQUIRE:
            # Create SSL context for asyncpg
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE
            _connect_args["ssl"] = ssl_context
        
        _engine = create_async_engine(
            settings.DATABASE_URL,
            echo=settings.DEBUG,
            pool_size=settings.DATABASE_POOL_SIZE,
            max_overflow=settings.DATABASE_MAX_OVERFLOW,
            pool_pre_ping=True,
            connect_args=_connect_args,
        )
    return _engine


@property
def engine():
    """Lazy-loaded engine property."""
    return _get_engine()


def _get_session_local():
    """Get or create the async session factory."""
    global _AsyncSessionLocal
    if _AsyncSessionLocal is None:
        _AsyncSessionLocal = async_sessionmaker(
            _get_engine(),
            class_=AsyncSession,
            expire_on_commit=False,
            autocommit=False,
            autoflush=False,
        )
    return _AsyncSessionLocal


# Convenience function to get the session factory
def get_AsyncSessionLocal():
    """Get the async session factory."""
    return _get_session_local()


# Base class for models
Base = declarative_base()


async def get_db() -> AsyncSession:
    """Dependency to get database session."""
    async with _get_session_local()() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db():
    """Initialize database tables."""
    async with _get_engine().begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def close_db():
    """Close database connections."""
    await _get_engine().dispose()
