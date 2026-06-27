"""Run the ingestion pipeline once and print results.

Usage:
    cd backend
    .venv/bin/python scripts/run_pipeline.py            # default: 20 articles
    .venv/bin/python scripts/run_pipeline.py --limit 5  # quicker test run
"""
import argparse
import asyncio
import logging
import sys
from pathlib import Path

# Ensure backend/ is on sys.path so `app.*` imports resolve when running as a script.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.services.pipeline import STORE, Pipeline  # noqa: E402

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)-7s %(name)s — %(message)s",
)


async def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=20)
    parser.add_argument("--concurrency", type=int, default=4)
    args = parser.parse_args()

    pipeline = Pipeline()
    stats = await pipeline.run(limit=args.limit, concurrency=args.concurrency)
    print()
    print("=" * 60)
    print(f"Discovered: {stats['discovered']}")
    print(f"Processed:  {stats['processed']}")
    print(f"Added:      {stats['added']}")
    print(f"Store size: {stats['store_size']}")
    print(f"Duration:   {stats['duration_sec']}s")
    print("=" * 60)

    print("\nSample (top 3 by published_at):")
    for a in STORE.list_sorted()[:3]:
        print(f"\n  • {a.title}")
        print(f"    {a.source.name} · trend_score={a.trend_score} · topics={a.topics}")
        if a.summary:
            print(f"    summary: {a.summary[:160]}")
        if a.key_points:
            for kp in a.key_points[:2]:
                print(f"      - {kp}")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
