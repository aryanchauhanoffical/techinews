from typing import List

from fastapi import APIRouter

from app.schemas.article import GithubRepo
from app.services.trends_service import TrendsService

router = APIRouter(prefix="/trends", tags=["trends"])
service = TrendsService()


@router.get("/topics")
async def trending_topics() -> List[dict]:
    return await service.trending_topics()


@router.get("/repos", response_model=List[GithubRepo])
async def trending_repos():
    return await service.trending_repos()


@router.get("/funding")
async def funding_events() -> List[dict]:
    return await service.funding_events()
