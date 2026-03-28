"""
Celery configuration for background tasks.
Note: For Railway deployment, you may want to disable Celery
and use alternative approaches like:
- Railway Cron for scheduled tasks
- Supabase Edge Functions for background jobs
- Redis Queue (RQ) for simple task queues
"""

from urllib.parse import urlparse

from celery import Celery
from app.core.config import settings


def _celery_broker_and_result_url() -> str | None:
    """Celery/Kombu only supports brokers like redis:// and amqp:// — not postgresql://."""
    raw = (settings.CELERY_BROKER_URL or settings.REDIS_URL or "").strip()
    if not raw:
        return None
    scheme = (urlparse(raw).scheme or "").lower()
    if scheme.startswith("postgres") or "postgres" in scheme:
        raise ValueError(
            "Celery needs a Redis URL (redis:// or rediss://), not PostgreSQL. "
            "On Railway, set REDIS_URL (or CELERY_BROKER_URL) from your Redis service, "
            "not from DATABASE_URL / Postgres."
        )
    return raw


# Celery app - disabled if no broker URL
celery_app = None

_broker = _celery_broker_and_result_url()
if _broker:
    celery_app = Celery(
        'bunga_trader',
        broker=_broker,
        backend=_broker,
        include=['app.services.celery_tasks']
    )
    
    celery_app.conf.update(
        task_serializer='json',
        accept_content=['json'],
        result_serializer='json',
        timezone='UTC',
        enable_utc=True,
        task_track_started=True,
        task_time_limit=300,  # 5 minutes max
        broker_connection_retry_on_startup=True,
    )
