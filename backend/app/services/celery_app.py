"""
Celery configuration for background tasks.
Note: For Railway deployment, you may want to disable Celery
and use alternative approaches like:
- Railway Cron for scheduled tasks
- Supabase Edge Functions for background jobs
- Redis Queue (RQ) for simple task queues
"""

from celery import Celery
from app.core.config import settings

# Celery app - disabled by default for simple deployments
# Enable if you have Redis provisioned
celery_app = None

if settings.REDIS_URL:
    celery_app = Celery(
        'bunga_trader',
        broker=settings.REDIS_URL,
        backend=settings.REDIS_URL,
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
