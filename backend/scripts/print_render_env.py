"""Print the values Render's blueprint form asks for, in form order.
Local helper only. Run: cd backend && .venv/bin/python scripts/print_render_env.py
"""
import json
import secrets
from pathlib import Path

from dotenv import dotenv_values

here = Path(__file__).resolve().parent.parent
env = dotenv_values(here / ".env")
fb = here / "secrets" / "firebase-admin.json"
order = ["MONGO_URI", "GEMINI_API_KEY", "GITHUB_TOKEN", "JINA_API_KEY", "FIRECRAWL_API_KEY",
         "CLOUDFLARE_ACCOUNT_ID", "CLOUDFLARE_API_TOKEN", "SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY"]
for k in order:
    print(f"{k}={env.get(k) or ''}")
print("FIREBASE_CREDENTIALS_JSON=" + (json.dumps(json.load(open(fb)), separators=(",", ":")) if fb.exists() else ""))
print("SECRET_KEY=" + (env.get("SECRET_KEY") or secrets.token_urlsafe(32)))
