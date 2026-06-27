# TechiNews Backend

FastAPI service for the TechiNews AI Tech Intelligence Platform.

## Quick start (local)

```bash
cd backend
cp .env.example .env
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

API will be on http://localhost:8000 — OpenAPI docs at http://localhost:8000/docs.

## Quick start (Docker)

```bash
cd backend
cp .env.example .env
docker compose up --build
```

This brings up `api`, `worker` (Celery), `mongo`, and `redis`.

## Structure

```
backend/
├── app/
│   ├── main.py                  # FastAPI entry
│   ├── core/                    # config, settings
│   ├── api/v1/                  # HTTP routes
│   ├── schemas/                 # Pydantic models (wire types)
│   ├── models/                  # Mongo document models
│   ├── db/                      # DB connection layer
│   ├── services/                # business logic
│   │   ├── scrapers/            # HN, Reddit, GitHub, X, Firecrawl, etc.
│   │   └── ai/                  # summarization, classification, embeddings
│   ├── workers/                 # Celery app + tasks
│   └── prompts/                 # LLM prompt templates
├── tests/
├── Dockerfile
├── docker-compose.yml
└── requirements.txt
```

## Endpoints (current stubs)

- `GET /health` — liveness
- `GET /api/v1/articles/feed` — personalized feed (in-memory stub)
- `GET /api/v1/articles/{id}` — single article
- `GET /api/v1/articles/search?q=` — text search
- `GET /api/v1/trends/topics`
- `GET /api/v1/trends/repos`
- `GET /api/v1/trends/funding`
- `POST /api/v1/auth/verify` — Firebase token verify (stub)
- `GET /api/v1/auth/me`
- `PATCH /api/v1/auth/me`

## Adding API keys

Edit `backend/.env` — keys read from there at boot via `app/core/config.py`. Never commit `.env`.
