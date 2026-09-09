"""Print the GitHub Actions secrets in NAME=value form from backend/.env and
backend/secrets/firebase-admin.json. Local helper only; never commit output.
Run: cd backend && .venv/bin/python scripts/print_secrets.py
"""
import json
import os
from pathlib import Path

from dotenv import dotenv_values

here = Path(__file__).resolve().parent.parent
env = dotenv_values(here / ".env")
mapping = {
    "MONGO_URI": env.get("MONGO_URI"),
    "GEMINI_API_KEY": env.get("GEMINI_API_KEY"),
    "GH_READ_TOKEN": env.get("GITHUB_TOKEN"),
    "JINA_API_KEY": env.get("JINA_API_KEY"),
    "FIRECRAWL_API_KEY": env.get("FIRECRAWL_API_KEY"),
    "CLOUDFLARE_ACCOUNT_ID": env.get("CLOUDFLARE_ACCOUNT_ID"),
    "CLOUDFLARE_API_TOKEN": env.get("CLOUDFLARE_API_TOKEN"),
    "SUPABASE_URL": env.get("SUPABASE_URL"),
    "SUPABASE_SERVICE_ROLE_KEY": env.get("SUPABASE_SERVICE_ROLE_KEY"),
    "ZYTE_API_KEY": env.get("ZYTE_API_KEY"),
    "REDIS_URL": env.get("REDIS_URL") or "",
}
fb = here / "secrets" / "firebase-admin.json"
mapping["FIREBASE_CREDENTIALS_JSON"] = json.dumps(json.load(open(fb)), separators=(",", ":")) if fb.exists() else ""
for k, v in mapping.items():
    flag = "" if v else "   <-- EMPTY, optional" if k == "REDIS_URL" else "   <-- MISSING"
    print(f"{k}={v or ''}{flag}")
