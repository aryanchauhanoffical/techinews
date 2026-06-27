"""Celery task stubs. Real implementations land as scrapers + AI services
come online."""
import asyncio

from app.services.scrapers.hackernews import HackerNewsScraper
from app.workers.celery_app import celery_app


@celery_app.task(name="app.workers.tasks.scrape_hackernews")
def scrape_hackernews():
    scraper = HackerNewsScraper()
    items = asyncio.run(scraper.fetch_front_page(limit=30))
    return {"fetched": len(items)}


@celery_app.task(name="app.workers.tasks.scrape_github_trending")
def scrape_github_trending():
    # TODO: implement GitHub trending scraper (Firecrawl or HTML parse)
    return {"fetched": 0, "note": "stub"}


@celery_app.task(name="app.workers.tasks.build_daily_digests")
def build_daily_digests():
    # TODO: per-user digest builder + FCM send
    return {"digests_sent": 0, "note": "stub"}
