web: cd backend && python serve.py
worker: cd backend && celery -A app.services.celery_app:celery_app worker --loglevel=info
scheduler: cd backend && celery -A app.services.celery_app:celery_app beat --loglevel=info
