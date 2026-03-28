from functools import lru_cache
from typing import List, Optional, Union
from urllib.parse import parse_qsl, urlencode, urlparse, urlunparse

from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # App
    APP_NAME: str = "Bunga Trader API"
    DEBUG: bool = False
    VERSION: str = "1.0.0"
    SECRET_KEY: str = "your-super-secret-key-change-this-in-production"
    API_V1_PREFIX: str = "/v1"
    
    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # Database
    DATABASE_URL: str = ""
    # Set true on hosts that require TLS (e.g. some public Railway/Postgres URLs)
    DATABASE_SSL_REQUIRE: bool = True
    DATABASE_POOL_SIZE: int = 20
    DATABASE_MAX_OVERFLOW: int = 10
    
    # Redis (empty = disabled; avoid default localhost in PaaS workers — it is never valid in-container)
    REDIS_URL: str = ""
    # Optional override for Celery only (otherwise REDIS_URL is used). Must be redis:// or rediss://.
    CELERY_BROKER_URL: str = ""
    REDIS_DB: int = 0
    
    # Security
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    PASSWORD_MIN_LENGTH: int = 8
    
    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "https://bungatrader.com",
        "https://app.bungatrader.com",
    ]
    
    # External APIs
    GROQ_API_KEY: str = ""
    GROQ_MODEL: str = "llama-3.3-70b-versatile"
    
    # Telegram (dashboard often leaves TELEGRAM_API_ID blank — must not crash Settings())
    TELEGRAM_API_ID: int = 0
    TELEGRAM_API_HASH: str = ""
    TELEGRAM_SESSION_NAME: str = "bunga_trader_session"
    TELEGRAM_SIGNAL_GROUPS: List[str] = []

    @field_validator("TELEGRAM_API_ID", mode="before")
    @classmethod
    def _telegram_api_id_empty(cls, v: Union[str, int, None]) -> int:
        if v is None or v == "":
            return 0
        return int(v)
    
    # M-Pesa (Safaricom Daraja API)
    MPESA_CONSUMER_KEY: str = ""
    MPESA_CONSUMER_SECRET: str = ""
    MPESA_PASSKEY: str = ""
    MPESA_SHORTCODE: str = "174379"
    MPESA_ENV: str = "sandbox"  # sandbox or production
    MPESA_CALLBACK_URL: str = "https://api.bungatrader.com/v1/webhooks/mpesa/callback"
    
    # MT5 ZeroMQ
    MT5_HOST: str = "localhost"
    MT5_PORT: int = 5555
    MT5_MAGIC_NUMBER: int = 123456
    MT5_TIMEOUT: int = 5000
    
    # Trading
    DEFAULT_RISK_PERCENT: float = 1.0
    MAX_RISK_PERCENT: float = 5.0
    MAX_DAILY_LOSS_PERCENT: float = 5.0
    MIN_RR_RATIO: float = 1.5
    SIGNAL_EXPIRY_MINUTES: int = 30
    
    # Notifications
    FIREBASE_PROJECT_ID: Optional[str] = None
    FIREBASE_PRIVATE_KEY: Optional[str] = None
    FIREBASE_CLIENT_EMAIL: Optional[str] = None
    
    # Monitoring
    SENTRY_DSN: Optional[str] = None
    ENABLE_METRICS: bool = True

    @model_validator(mode="after")
    def use_asyncpg_driver_for_postgres(self) -> "Settings":
        """Railway/Render/etc. often set DATABASE_URL=postgresql://…; async SQLAlchemy needs asyncpg."""
        url = (self.DATABASE_URL or "").strip()
        if not url:
            return self
        if url.startswith("postgres://"):
            url = "postgresql+asyncpg://" + url[len("postgres://") :]
        elif url.startswith("postgresql://") and not url.startswith("postgresql+asyncpg://"):
            url = "postgresql+asyncpg://" + url[len("postgresql://") :]

        # asyncpg does not use libpq sslmode=; strip it and enable TLS via connect_args instead
        ssl_required = bool(self.DATABASE_SSL_REQUIRE)
        if "sslmode=" in url.lower():
            parsed = urlparse(url)
            pairs = []
            for key, val in parse_qsl(parsed.query, keep_blank_values=True):
                if key.lower() == "sslmode" and val.lower() in (
                    "require",
                    "verify-full",
                    "verify-ca",
                ):
                    ssl_required = True
                    continue
                pairs.append((key, val))
            url = urlunparse(parsed._replace(query=urlencode(pairs)))

        object.__setattr__(self, "DATABASE_URL", url)
        if ssl_required:
            object.__setattr__(self, "DATABASE_SSL_REQUIRE", True)
        return self

    class Config:
        env_file = None
        env_file_encoding = "utf-8"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
