"""Run the ingestion pipeline once and print stats as JSON.

Usage:
    cd backend
    .venv/bin/python scripts/run_pipeline.py             # default: enrich top 30
    .venv/bin/python scripts/run_pipeline.py --limit 5   # quick test
    .venv/bin/python scripts/run_pipeline.py --dry-run   # collect + rank only, no LLM, no writes
"""
import argparse
import asyncio
import json
import logging
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.db import mongo  # noqa: E402
from app.services.pipeline import Pipeline  # noqa: E402

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)-7s %(name)s — %(message)s")


async def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--limit", type=int, default=30)
    p.add_argument("--concurrency", type=int, default=4)
    p.add_argument("--dry-run", action="store_true")
    args = p.parse_args()

    pipe = Pipeline()
    if args.dry_run:
        from app.services.ranking import rank
        items = rank(await pipe.collect())
        by_src = {}
        for a in items:
            by_src[a.source.name] = by_src.get(a.source.name, 0) + 1
        print(json.dumps({"collected": len(items), "by_source": by_src}, indent=2))
        for a in items[:25]:
            cov = f"x{a.coverage}" if a.coverage > 1 else "  "
            print(f"{a.trend_score:3d} {cov} {a.source.name[:18]:18s}  {a.title[:80]}")
        return 0

    await mongo.connect()
    try:
        stats = await pipe.run(limit=args.limit, concurrency=args.concurrency)
    finally:
        await mongo.close()
    print(json.dumps(stats, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
