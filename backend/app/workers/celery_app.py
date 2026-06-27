from celery import Celery

from app.core.config import get_settings

settings = get_settings()

celery_app = Celery(
    "techinews",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=["app.workers.tasks"],
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
)

# Periodic schedule (Beat). Real scrapers will replace these no-op tasks.
celery_app.conf.beat_schedule = {
    "hackernews-every-15min": {
        "task": "app.workers.tasks.scrape_hackernews",
        "schedule": 15 * 60,
    },
    "github-trending-hourly": {
        "task": "app.workers.tasks.scrape_github_trending",
        "schedule": 60 * 60,
    },
    "daily-digest-build": {
        "task": "app.workers.tasks.build_daily_digests",
        "schedule": 24 * 60 * 60,
    },
}
