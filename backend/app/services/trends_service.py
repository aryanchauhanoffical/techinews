from datetime import datetime, timedelta
from typing import List

from app.schemas.article import GithubRepo


class TrendsService:
    async def trending_topics(self) -> List[dict]:
        return [
            {"id": "t1", "name": "GPT-5.5", "description": "10M context + agentic tools", "article_count": 142, "growth_percent": 1840},
            {"id": "t2", "name": "Llama 4", "description": "Open 405B commercial license", "article_count": 98, "growth_percent": 920},
            {"id": "t3", "name": "Rust in Kernel", "description": "Async runtime in mainline 6.13", "article_count": 64, "growth_percent": 412},
        ]

    async def trending_repos(self) -> List[GithubRepo]:
        now = datetime.utcnow()
        return [
            GithubRepo(
                id="tr1",
                full_name="meta-llama/llama4",
                description="Reference implementation for Llama 4",
                url="https://github.com/meta-llama/llama4",
                language="Python",
                stars=14200,
                forks=1840,
                stars_this_week=8920,
                last_commit=now - timedelta(days=1),
            ),
            GithubRepo(
                id="tr2",
                full_name="oven-sh/bun",
                description="Incredibly fast JavaScript runtime",
                url="https://github.com/oven-sh/bun",
                language="Zig",
                stars=82400,
                forks=3120,
                stars_this_week=2840,
                last_commit=now,
            ),
        ]

    async def funding_events(self) -> List[dict]:
        now = datetime.utcnow()
        return [
            {
                "id": "f1",
                "company_name": "Anthropic",
                "round": "Series F",
                "amount_usd": 8_000_000_000,
                "investors": ["Google", "Mubadala", "Lightspeed"],
                "description": "Push Claude into enterprise; $5B for compute.",
                "announced_at": now.isoformat(),
            },
            {
                "id": "f2",
                "company_name": "Lovable",
                "round": "Series B",
                "amount_usd": 200_000_000,
                "investors": ["Accel", "Index Ventures"],
                "description": "AI app builder hits 1M devs.",
                "announced_at": (now - timedelta(days=1)).isoformat(),
            },
        ]
