# Work Done — AI Tech Intelligence Platform

> Living log of completed work. Updated as the project progresses.
> Format: `[YYYY-MM-DD] — Phase X.Y — Description` + linked files where relevant.

---

## Project Baseline (2026-05-24)

What existed when this log was created:
- Default Flutter project scaffold (`flutter create`)
- `pubspec.yaml` with only `cupertino_icons` + `flutter_lints`
- `lib/main.dart` — default counter demo
- `idea/idea.md`, `idea/stck.md` — product + stack docs
- Planning docs: [WORK_TO_BE_DONE.md](WORK_TO_BE_DONE.md), [REQUIREMENTS_NEEDED.md](REQUIREMENTS_NEEDED.md), [WORK_DONE.md](WORK_DONE.md)

---

## Sprint 1 — MVP scaffold end-to-end (2026-05-24)

Goal: stand up the full Flutter app skeleton + backend skeleton with mock data so the product can be felt end-to-end before any API keys land.

### Phase 0 — Foundations
- [Phase 0.1] Replaced [pubspec.yaml](pubspec.yaml) — added Riverpod, GoRouter, Dio, Hive, Freezed, GoogleFonts, CachedNetworkImage, Shimmer, ShareePlus, UrlLauncher, FlutterSecureStorage, FlutterDotenv, Logger, InAppWebView + dev-deps for codegen
- [Phase 0.1] Built [lib/](lib/) folder architecture: `app/`, `core/{theme,constants,utils,widgets,errors,network}/`, `data/{models,mock,repositories}/`, `services/`, `features/{auth,onboarding,feed,article,discover,search,profile,notifications,shell}/presentation/`
- [Phase 0.1] Created [assets/](assets/) folders (`images/`, `icons/`, `mock/`)
- [Phase 0.1] Extended [.gitignore](.gitignore) with `.env`, Firebase configs, Python venvs
- [Phase 0.1] Created [.env.example](.env.example) + working `.env` for Flutter
- [Phase 0.1] Replaced [lib/main.dart](lib/main.dart) — clean entry with `ProviderScope` + portrait lock
- [Phase 0.1] [lib/app/app.dart](lib/app/app.dart) — `TechiNewsApp` root with `MaterialApp.router`
- [Phase 0.2] Created [backend/](backend/) project structure (FastAPI)
- [Phase 0.2] [backend/requirements.txt](backend/requirements.txt) — FastAPI, Motor, Redis, Celery, OpenAI, Gemini, Anthropic, PRAW, httpx, Firebase Admin
- [Phase 0.2] [backend/.env.example](backend/.env.example) — every required env var grouped by service
- [Phase 0.2] [backend/Dockerfile](backend/Dockerfile) + [backend/docker-compose.yml](backend/docker-compose.yml) — api + worker + mongo + redis
- [Phase 0.2] [backend/README.md](backend/README.md) — local + docker quick-start

### Design System (Modern Dark / Cinema Mobile aesthetic)
- Locked design direction via `ui-ux-pro-max` skill: dark-first, Linear/Arc/Vercel vibe — no pure black, hairline borders, 16-20px card radius, Bezier(0.16, 1, 0.3, 1) easing, press-scale 0.97 → 1.0
- [lib/core/theme/app_colors.dart](lib/core/theme/app_colors.dart) — indigo `#6366F1` + cyan `#06B6D4`, graded dark surfaces (#020203/#050506/#0A0A0C), topic color helper, ambient + brand gradients
- [lib/core/theme/app_typography.dart](lib/core/theme/app_typography.dart) — Inter (body) + Space Grotesk (display) via Google Fonts
- [lib/core/theme/app_spacing.dart](lib/core/theme/app_spacing.dart) — 4/8dp rhythm + radius tokens
- [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart) — full Material 3 light + dark themes
- [lib/core/widgets/press_scale.dart](lib/core/widgets/press_scale.dart) — animated press feedback widget with haptic
- [lib/core/widgets/ambient_background.dart](lib/core/widgets/ambient_background.dart) — animated indigo/cyan glow blobs
- [lib/core/widgets/topic_chip.dart](lib/core/widgets/topic_chip.dart) — pill chip with topic-driven coloring
- [lib/core/widgets/loading_shimmer.dart](lib/core/widgets/loading_shimmer.dart) — shimmer + feed-card skeleton
- [lib/core/utils/format.dart](lib/core/utils/format.dart) — relative time, money, compact number
- [lib/core/constants/app_constants.dart](lib/core/constants/app_constants.dart) — interests catalog + storage keys

### Phase 1 — Data layer + services
- Domain models (all in [lib/data/models/](lib/data/models/)): `Article`, `ArticleSource`, `GithubRepo`, `SocialPost`, `AppUser`, `NotificationItem`, `TrendingTopic`, `FundingEvent`
- Mock fixtures (all in [lib/data/mock/](lib/data/mock/)): `MockArticles` (8 realistic stories), `MockTrends` (topics + repos + funding), `MockNotifications`, `MockSources`
- Repository interfaces + mock impls ([lib/data/repositories/](lib/data/repositories/)): `ArticleRepository`, `TrendsRepository`, `NotificationsRepository`, `AuthRepository`
- [lib/services/providers.dart](lib/services/providers.dart) — all Riverpod providers (`feedProvider`, `articleProvider`, `searchResultsProvider`, `trendingTopicsProvider`, `trendingReposProvider`, `fundingEventsProvider`, `notificationsListProvider`, `currentUserProvider`, `themeModeProvider`)

### Phase 1 — Auth & onboarding UI
- [lib/features/onboarding/presentation/splash_screen.dart](lib/features/onboarding/presentation/splash_screen.dart) — animated splash with brand gradient + logo glow → auto-routes to onboarding after 1.6s
- [lib/features/onboarding/presentation/onboarding_screen.dart](lib/features/onboarding/presentation/onboarding_screen.dart) — 3-page PageView: welcome value-prop → interest multi-select (Wrap of chips) → notification preference (Instant/Daily/Weekly/Silent)
- [lib/features/auth/presentation/sign_in_screen.dart](lib/features/auth/presentation/sign_in_screen.dart) — Google/Apple/GitHub/Email buttons over animated ambient background, primary CTA has accent glow shadow

### Phase 6 + 8 — Feed (the centerpiece)
- [lib/features/feed/presentation/feed_screen.dart](lib/features/feed/presentation/feed_screen.dart) — vertical `PageView.builder` (Inshorts-style), header with TechiNews logo + position counter, pull-to-refresh, error + empty states
- [lib/features/feed/presentation/widgets/feed_card.dart](lib/features/feed/presentation/widgets/feed_card.dart) — hero image with gradient overlay, source chip, headline (Space Grotesk), AI summary, topic chips, AI Key Points box (indigo tinted), Save/Share/Trend-score action row

### Phase 8.3 — Article detail
- [lib/features/article/presentation/article_detail_screen.dart](lib/features/article/presentation/article_detail_screen.dart) — `SliverAppBar` with parallax hero, AI Summary section, Why It Matters box, Key Points list, Related Repositories, Community Discussions, "Read full article" CTA, share + save in app bar
- [lib/features/article/presentation/widgets/repo_card.dart](lib/features/article/presentation/widgets/repo_card.dart) — GitHub repo card with language, stars, +stars-this-week badge
- [lib/features/article/presentation/widgets/discussion_card.dart](lib/features/article/presentation/widgets/discussion_card.dart) — Reddit/X/HN post card with upvotes + comments

### Phase 8.4–8.6 — Discover / Search / Profile / Notifications
- [lib/features/discover/presentation/discover_screen.dart](lib/features/discover/presentation/discover_screen.dart) — horizontal scrolling trending topic cards (with topic colors + growth %), trending repos list, funding events list (round badge + amount + investor chips)
- [lib/features/search/presentation/search_screen.dart](lib/features/search/presentation/search_screen.dart) — search field with clear button, suggestion chips (empty state), live results, no-results state
- [lib/features/notifications/presentation/notifications_screen.dart](lib/features/notifications/presentation/notifications_screen.dart) — categorized notifications (breaking/funding/github/digest/hiring), unread accent border + dot, tap → article detail, mark-all-read
- [lib/features/profile/presentation/profile_screen.dart](lib/features/profile/presentation/profile_screen.dart) — avatar + name + PRO badge, 3 stat cards, grouped menu sections (Your Content / Preferences / Account) with destructive sign-out styling
- [lib/features/profile/presentation/saved_screen.dart](lib/features/profile/presentation/saved_screen.dart) — saved-article list with empty state
- [lib/features/profile/presentation/settings_screen.dart](lib/features/profile/presentation/settings_screen.dart) — notification mode, theme mode (system/light/dark), interests editor, About section

### Phase 8.1 — Navigation
- [lib/features/shell/main_shell.dart](lib/features/shell/main_shell.dart) — custom 5-tab bottom nav (Feed / Discover / Search / Inbox / Profile) with selected-state indigo highlight, safe area aware
- [lib/app/router.dart](lib/app/router.dart) — GoRouter with `ShellRoute` for tabbed screens + top-level routes for splash, onboarding, sign-in, article detail, saved, settings

### Tooling / verification
- `flutter pub get` ✓ (146 packages resolved; bumped `custom_lint` to `^0.7.3` + `riverpod_lint` to `^2.6.3` for analyzer 7.x compat)
- `flutter analyze` ✓ (0 errors, 30 info-level lints — deprecations + unused-underscore in callbacks, not blocking)
- [test/widget_test.dart](test/widget_test.dart) — replaced default counter test with app-boots smoke test

### Backend — FastAPI scaffold (stubbed, ready for real keys)
- [backend/app/main.py](backend/app/main.py) — FastAPI app with CORS, lifespan, health endpoint, OpenAPI docs
- [backend/app/core/config.py](backend/app/core/config.py) — `pydantic-settings` reading `.env` (every key from REQUIREMENTS_NEEDED.md)
- [backend/app/schemas/article.py](backend/app/schemas/article.py) + [backend/app/schemas/user.py](backend/app/schemas/user.py) — Pydantic wire models matching Flutter side
- [backend/app/api/v1/articles.py](backend/app/api/v1/articles.py) — `/feed`, `/{id}`, `/search`
- [backend/app/api/v1/trends.py](backend/app/api/v1/trends.py) — `/topics`, `/repos`, `/funding`
- [backend/app/api/v1/auth.py](backend/app/api/v1/auth.py) — `/verify`, `/me`, `/logout` (stubbed pending Firebase Admin)
- [backend/app/services/feed_service.py](backend/app/services/feed_service.py) + [backend/app/services/trends_service.py](backend/app/services/trends_service.py) — in-memory stubs to be replaced with Mongo repositories
- [backend/app/services/ai/summarizer.py](backend/app/services/ai/summarizer.py) — OpenAI-backed summarizer skeleton (returns stub output until `OPENAI_API_KEY` set)
- [backend/app/services/scrapers/hackernews.py](backend/app/services/scrapers/hackernews.py) — working scraper (uses public Algolia API — no key needed)
- [backend/app/workers/celery_app.py](backend/app/workers/celery_app.py) + [backend/app/workers/tasks.py](backend/app/workers/tasks.py) — Celery app + Beat schedule (HN every 15min, GitHub hourly, daily digest builder)

### What user-flow you can demo end-to-end today
Splash → onboarding (welcome → interests → notifications) → sign-in → main shell with 5 tabs (Feed swipe / Discover trends / Search / Notifications / Profile) → tap any card → article detail with AI summary, key points, related repos, discussions → share / save / open full article. Theme switches light/dark from settings. All backed by mock data — zero external dependencies to demo.

---

## Sprint 2 — Real ingestion pipeline + backend wiring (2026-05-24)

Goal: kill mock data, ship the real pipeline (`NewsAPI → Jina → Gemini → store → FastAPI → Flutter`).

### API audit (from `everyapi.md`)
- Wrote [backend/scripts/test_apis.py](backend/scripts/test_apis.py) — single-call smoke test against all 10 APIs in `everyapi.md`
- **4 working:** Gemini (`gemini-2.5-flash` — `gemini-1.5-flash` is deprecated), NewsAPI.org, Jina Reader, Firecrawl
- **6 failing:** All Cloudflare `cfut_…` tokens (Claude Opus, Claude Sonnet, OpenAI GPT-5.4-pro, Grok Imagine, gpt-image-2, Alibaba wan-2.6). Tokens authenticate (verify endpoint → `success: true`) but every model call returns Cloudflare error 2021 "Invalid User Credentials". These are 3rd-party partner models requiring Workers AI Paid billing or AI Gateway BYOK.
- Briefly built + deployed a Cloudflare Worker proxy ([techinews-ai-proxy.techinews-ai.workers.dev](https://techinews-ai-proxy.techinews-ai.workers.dev)) to retry via `env.AI.run()` binding — same error. **Approach abandoned per user decision; worker code deleted, Worker removed from CF account.**

### Backend — the pipeline
- [backend/app/services/scrapers/newsapi.py](backend/app/services/scrapers/newsapi.py) — NewsAPI client with `top-headlines` + topic-search modes. Custom domain → friendly-name mapping (TechCrunch, The Verge, etc.). Drops broad `category=technology` (sport/entertainment leakage) — uses focused topic queries instead.
- [backend/app/services/scrapers/jina_reader.py](backend/app/services/scrapers/jina_reader.py) — Primary article extractor via `r.jina.ai/{url}`. 45s timeout. Returns clean markdown.
- [backend/app/services/scrapers/firecrawl.py](backend/app/services/scrapers/firecrawl.py) — Fallback extractor for JS-rendered pages. 60s timeout.
- [backend/app/services/ai/summarizer.py](backend/app/services/ai/summarizer.py) — Gemini-backed structured-JSON summarizer. Returns `summary` / `key_points` / `why_it_matters` / `topics` / `companies` / `stack` / `trend_score`. Disables Gemini 2.5 Flash "thinking" tokens (`thinkingBudget: 0`) which were eating the 1024-token output budget and truncating JSON mid-string. Tolerant JSON parser handles stray code fences. **Has a process-wide 429 circuit breaker** — once Gemini quota is exhausted, further calls short-circuit to the fallback instead of burning HTTP requests.
- [backend/app/services/pipeline.py](backend/app/services/pipeline.py) — Orchestrator: `discover() → extract() → summarize() → STORE.upsert_many()`. Thread-safe in-memory store (200-item cap, dedup-on-URL, LRU by `published_at`). Concurrency-bounded via `asyncio.Semaphore`.
- [backend/app/services/feed_service.py](backend/app/services/feed_service.py) — Replaced in-memory mock data with `STORE`-backed reads. Interests-first ranking, then chronological. `min_trend=30` filter drops the low-signal articles Gemini already flagged.

### Backend — wiring
- [backend/app/main.py](backend/app/main.py) — `lifespan` boots the pipeline asynchronously on startup when store is empty (skip with `SKIP_BOOT_PIPELINE=1` env). Pulls 15 articles at concurrency=3.
- [backend/app/api/v1/admin.py](backend/app/api/v1/admin.py) — `POST /api/v1/admin/pipeline/run?limit=&concurrency=` to trigger ingestion manually; `GET /api/v1/admin/store` for size check.
- [backend/scripts/run_pipeline.py](backend/scripts/run_pipeline.py) — Manual CLI runner that prints per-article diagnostics + top-3 sample.

### Flutter — real backend integration
- [lib/core/network/api_client.dart](lib/core/network/api_client.dart) — Dio client with smart base-URL resolution (env override → emulator default 10.0.2.2 → simulator/desktop default 127.0.0.1)
- [lib/data/repositories/api_article_repository.dart](lib/data/repositories/api_article_repository.dart) — HTTP `ArticleRepository` implementation. JSON-to-model mappers (backend snake_case ↔ Flutter camelCase), preserves local save/read state per session.
- [lib/services/providers.dart](lib/services/providers.dart) — `articleRepositoryProvider` reads `USE_MOCK_DATA` from `.env`. `false` → real backend, `true` → mock. `dioProvider` exposes the configured client.
- [lib/main.dart](lib/main.dart) — `dotenv.load()` before `runApp`, safely tolerates missing `.env`.
- [.env](.env) — flipped to `USE_MOCK_DATA=false`, `API_BASE_URL=http://127.0.0.1:8000`.

### Cleanup
- Removed `cloudflare-worker/` folder entirely
- Removed all CF_* / WORKER_* / CLOUDFLARE_* env vars from `backend/.env` and `backend/.env.example`
- Removed dead test scripts (`probe_cf.py`, `probe_cf2.py`, `test_worker.py`)
- `flutter analyze` still 0 errors, 30 info-lints (unchanged from sprint 1)

### Verified end-to-end
- ✅ NewsAPI returns 50+ articles per pipeline run
- ✅ Jina extracts clean markdown (10-120K chars per article)
- ✅ Gemini produces structured JSON summaries with topics + key_points + why_it_matters
- ✅ Backend `/api/v1/articles/feed?page_size=N` returns real articles with full schema
- ✅ Backend running locally on `http://127.0.0.1:8000` — Flutter `ApiArticleRepository` reads it
- ⚠️ Gemini free-tier quota (250K tokens/day) exhausted during dev testing — auto-resets daily. The 429 circuit breaker now prevents further wasted calls.

### How to test the live pipeline tomorrow (after Gemini quota resets)
```bash
# Terminal 1 — backend
cd backend && SKIP_BOOT_PIPELINE=1 .venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000

# Trigger ingestion manually
curl -X POST "http://127.0.0.1:8000/api/v1/admin/pipeline/run?limit=15"

# Inspect
curl "http://127.0.0.1:8000/api/v1/articles/feed?page_size=5" | python3 -m json.tool

# Terminal 2 — Flutter
flutter run -d macos     # or chrome / iOS / Android
```

---

## Sprint 2 — Live pipeline re-verification (2026-06-27)

Picked the project back up after a ~5-week gap. Confirmed the real ingestion pipeline still works end-to-end now that the Gemini free-tier quota has long since reset.

- Booted backend clean (`SKIP_BOOT_PIPELINE=1`) — `/health` green in <1s, no startup errors after the layoff.
- Verified all 4 blocker keys still present + non-empty in `backend/.env` (Gemini, NewsAPI, Jina, Firecrawl).
- `POST /api/v1/admin/pipeline/run?limit=8&concurrency=3` → `{discovered:54, processed:8, added:8, store_size:8, duration_sec:29}`. Gemini summaries generating again (no 429).
- `GET /api/v1/articles/feed?page_size=3` → real articles with full schema: `summary`, 4 `key_points` each, `why_it_matters`, `topics`, `trend_score`.
- ⚠️ **Content-relevance drift observed:** top results skewed general/finance (Musk net worth, a DBA university program, GIFT Nifty stocks) rather than developer/AI news. NewsAPI topic queries + trend filter need tightening for the target audience. Logged as the next refinement candidate.

---

## Pending Phases

### Phase 2 — Data Ingestion / Scraping
- _Scaffolded (HN done). Reddit, GitHub, X, Product Hunt, RSS pending real keys._

### Phase 3 — AI Processing
- _Summarizer skeleton in place; LLM call wires up the moment `OPENAI_API_KEY` lands._

### Phase 4 — GitHub Intelligence
- _Pending GitHub token._

### Phase 5 — Social Intelligence
- _Pending Reddit/X keys._

### Phase 6 — Recommendation Engine
- _Phase-1 rule-based ranking lives inside `FeedService.get_feed`. ML phase pending._

### Phase 7 — Notifications
- _UI complete. FCM wiring pending Firebase service account._

### Phase 9 — Caching & Performance
- _Not started. Redis already in compose._

### Phase 10 — Analytics & Monitoring
- _Not started. PostHog + Sentry placeholders in `.env.example`._

### Phase 11 — Search Infrastructure
- _Mock-backed today. Typesense integration pending._

### Phase 12 — Monetization
- _Not started._

### Phase 13 — Deployment & CI/CD
- _Dockerfile + compose ready. GitHub Actions not started._

### Phase 14 — Security & Hardening
- _Not started._

### Phase 15 — Testing
- _Smoke test only. Real suites pending._
