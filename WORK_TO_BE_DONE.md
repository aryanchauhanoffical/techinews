# Work To Be Done — AI Tech Intelligence Platform

> Complete build plan from scratch. The current project is an empty Flutter starter (default counter app). Everything below needs to be built.

---

## Phase S — Shipaton 2026 Next Gen submission (deadline 2026-09-30 11:45pm PDT)

> Judged on: app idea clarity, functional progress, thoughtful RevenueCat integration, technical choices. Video + open-source repo. No store release.

**User (Sep 6–7):** Devpost account with academic email + join Shipaton · RevenueCat project + Test Store app → API key · GitHub Actions secrets.

**Build (Sep 6–12)**
- [x] Feed quality: story clustering (coverage count), 36 h recency half-life, equal lab weights, hourly re-score of the 10-day window
- [x] Images: GitHub OG cards, image-only OG pass for new items + 40/run backfill, typographic fallback tile in app (49% → 21% missing)
- [x] Feed: "From GitHub" section, infinite scroll, coverage badge, "Also covered by" on article
- [x] RevenueCat: purchases_flutter 10.11, `pro` entitlement, Ink paywall (`/pro`), gating (Instant alerts, 10-save free cap), restore, logIn on sign-in. Test Store key in .env; catalog created via API v2 (entitlement `pro`, `pro_monthly`, `pro_annual`, offering `default`). **Prices + 7-day trial still to set in dashboard; not yet run on Android.**
- [x] Topic alerts setting (Pro) — UI, device-stored · [ ] backend push filter once profile sync lands
- [x] `render.yaml` blueprint + `FIREBASE_CREDENTIALS_JSON` support · [ ] **user clicks Deploy on Render** · [ ] app pointed at Render URL · [ ] **Actions secrets (user)** → hourly cron + push job live
- [x] README for judges: architecture, sourcing v2, ranking, RevenueCat design, how to run

**Ship (Sep 20–29)**
- [ ] Demo video script (≤2 min, device recording ~Sep 24)
- [ ] 1024² icon + screenshots (optional for Next Gen, include anyway)
- [ ] Devpost text: features, RevenueCat story, tech choices
- [ ] Submit by Sep 28 (buffer)

---

## Phase 0 — Foundations (Setup)

### 0.1 Flutter Project Setup
- [ ] Replace default `lib/main.dart` counter app
- [ ] Configure `pubspec.yaml` with all required dependencies
- [ ] Set up folder architecture (`lib/core`, `lib/features`, `lib/data`, `lib/presentation`, `lib/services`)
- [ ] Add app icon and splash screen
- [ ] Configure app name, bundle ID, and metadata (Android `applicationId`, iOS `CFBundleIdentifier`)
- [ ] Set minimum SDK versions (Android API 23+, iOS 13+)
- [ ] Add `.env` support via `flutter_dotenv`
- [ ] Configure linting rules in `analysis_options.yaml`

### 0.2 Backend Project Setup (FastAPI)
- [ ] Initialize Python project (`pyproject.toml` / `requirements.txt`)
- [ ] Set up FastAPI base app structure
- [ ] Configure environment variables (`.env`)
- [ ] Set up Docker + `docker-compose.yml` for local dev
- [ ] Configure logging (structured JSON logs)
- [ ] Set up Alembic-style migrations or MongoDB schema docs
- [ ] Configure CORS for Flutter client

### 0.3 Infrastructure Setup
- [ ] MongoDB Atlas cluster (free tier)
- [ ] Redis Cloud instance (free tier)
- [ ] Firebase project (Auth + FCM + Crashlytics + Analytics)
- [ ] Cloudflare account for CDN/DDoS
- [ ] Render or Railway account for backend hosting
- [ ] GitHub repo + GitHub Actions CI/CD pipeline

---

## Phase 1 — Authentication & User Onboarding

### 1.1 Backend
- [ ] User model in MongoDB (uid, email, name, interests, preferences, FCM token, created_at)
- [ ] Firebase Admin SDK integration for token verification
- [ ] `/auth/verify` endpoint (verify Firebase ID token, create/fetch user)
- [ ] `/auth/me` endpoint (get current user)
- [ ] `/auth/logout` endpoint
- [ ] JWT middleware for protected routes

### 1.2 Flutter
- [ ] Firebase Auth integration (`firebase_auth`, `google_sign_in`, `sign_in_with_apple`)
- [ ] Login screen (Google, Apple, GitHub, Email OTP)
- [ ] Splash screen with auth state check
- [ ] Auth state management (Riverpod)
- [ ] Secure token storage (`flutter_secure_storage`)
- [ ] Onboarding flow (welcome → interests → notification preferences)
- [ ] Interest selection screen (multi-select chips: AI, Startups, GitHub, etc.)
- [ ] Notification preference screen (instant / daily / weekly / silent)
- [ ] Profile screen (edit interests, sign out, delete account)

---

## Phase 2 — Data Ingestion Layer (Backend) — **v2, council verdict 2026-09-05**

> Decision: no scraper sprawl, no self-bot "agents". Keyless structured feeds
> first, LLM only on the ranked top-N, collector runs as a GitHub Actions cron
> (no VM, no Celery). Uniqueness metric = items surfaced that are NOT on the HN
> front page (`unique_vs_hn` in pipeline stats).

### 2.1 Collectors (all keyless unless noted)
- [x] RSS/Atom collector — 25 feeds: lab blogs, press, newsletters, dev-tool blogs, subreddit `.rss`, Product Hunt (`app/services/sources.py`)
- [x] GitHub release Atom feeds for 12 key repos (ollama, llama.cpp, vllm, transformers, …)
- [x] Hacker News (Algolia front page)
- [x] GitHub search API — new repos ≥150★ in 7d + topic:llm / ai-agents / mcp (token = 5k req/h)
- [x] arXiv API — cs.AI / cs.LG / cs.CL newest
- [x] Hugging Face — daily papers + trending models (HF_TOKEN optional)
- [x] Listing-page collector for sites without feeds — Anthropic news, Meta AI blog (`html_list.py`)
- [ ] RSSHub (self-hosted) for public Telegram channels / Bluesky — only if uniqueness metric stalls
- [ ] Official TechiNews Discord/Telegram **bot** that communities invite (opt-in) — Phase 5, not a self-bot
- [ ] YouTube channel RSS (AI labs, key creators)
- [ ] Reddit: r/LocalLLaMA, r/artificial, r/programming still 429 even serialized — try 10s gap or drop
- ~~NewsAPI~~ removed (dev-only licence, 24h delay, 100 req/day)
- ~~Reddit Data API app~~ dropped (moderation-only approval flow); subreddit RSS used instead

### 2.2 Ranking / dedup (no LLM cost)
- [x] Heuristic score: source weight × type base + hot-term hits + engagement (points/stars/upvotes) + recency (`ranking.py`)
- [x] Cross-source dedup: URL + title token Jaccard ≥ 0.75
- [x] Per-source cap (4) before enrichment so corporate feeds can't flood the top
- [ ] Learn weights from user engagement once the app has traffic (Phase 6)

### 2.3 Extraction / enrichment
- [x] Local extraction with trafilatura (free) → Jina → Firecrawl fallback (`extract.py`)
- [x] Gemini summary only for top-N per run (default 30); everything else stored with its feed summary
- [x] Image: source image → OG image → Cloudflare Workers AI FLUX.1-schnell generated + uploaded to Supabase Storage, generation only when score ≥ 75 (`images.py`)
- [ ] Repo linking: match enriched articles to GitHub repos mentioned in body (Phase 4)

### 2.4 Scheduling
- [x] `.github/workflows/collect.yml` — every 3h + manual dispatch; secrets listed in REQUIREMENTS_NEEDED §5
- [ ] Add repo secrets on GitHub (user action) and run the workflow once by hand
- [ ] Alert (workflow failure → email) — GitHub does this by default for the repo owner
- ~~Celery Beat / worker~~ removed

### 2.5 Feed
- [x] Feed order: last 10 days, trend_score desc then newest (was date-only)
- [ ] "New since you last opened" divider in the app (freshness signal)

---

## Phase 3 — AI Processing Layer (Backend)

### 3.1 AI Summarization
- [ ] LLM client wrapper (supports OpenAI + Gemini)
- [ ] Article summarizer (1-line headline, 30-second TL;DR, 3 key points)
- [ ] "Why it matters" insight extractor
- [ ] Prompt templates stored in `prompts/` folder
- [ ] Token usage tracking + cost logging

### 3.2 Categorization & Tagging
- [ ] Topic classifier (AI, Startup, Cybersecurity, etc.)
- [ ] Company entity extraction (OpenAI, Google, Apple, etc.)
- [ ] Tech stack tagging (Python, React, LLM, etc.)
- [ ] Trend level scoring (1-10)
- [ ] Virality score (based on social signals)
- [ ] Sentiment analysis (positive / neutral / negative)

### 3.3 Embeddings & Semantic Search
- [ ] Embedding generation (OpenAI `text-embedding-3-small` or Gemini)
- [ ] Vector storage (MongoDB Atlas Vector Search or Typesense)
- [ ] Similar-article matching
- [ ] Semantic search endpoint

---

## Phase 4 — GitHub Intelligence Service

- [ ] GitHub REST + GraphQL API integration
- [ ] Trending repo fetcher (daily / weekly)
- [ ] AI-driven repo matcher: given article → find related repos
- [ ] Repo enrichment (stars, forks, language, last commit, README excerpt)
- [ ] Open-source alternative finder
- [ ] "Repos related to this news" endpoint

---

## Phase 5 — Social Intelligence Service

- [ ] Reddit discussion fetcher tied to article topics
- [ ] X/Twitter thread fetcher tied to article topics
- [ ] Community sentiment aggregator
- [ ] Viral thread detector
- [ ] "Community response" endpoint per article

---

## Phase 6 — Recommendation Engine

### 6.1 Phase 1 (Rule-Based)
- [ ] User interest matching
- [ ] Recency boost
- [ ] Popularity score weighting
- [ ] Trend level weighting
- [ ] Personalized feed endpoint `/feed`

### 6.2 Phase 2 (ML-Based) — Future
- [ ] User behavior event tracking (read, save, skip, share)
- [ ] Collaborative filtering
- [ ] Embedding similarity ranking

---

## Phase 7 — Notification System

### 7.1 Backend
- [ ] FCM Admin SDK integration
- [ ] Notification scheduler (Celery Beat)
- [ ] Instant notification trigger (when high-trend article ingested matching user interests)
- [ ] Daily digest builder (top 5 per user)
- [ ] Weekly digest builder
- [ ] Notification preference filtering
- [ ] Quiet hours support
- [ ] Notification history storage

### 7.2 Flutter
- [ ] FCM token registration on login
- [ ] Foreground notification handler
- [ ] Background notification handler
- [ ] Notification tap → deep link to article
- [ ] Notification preferences UI
- [ ] In-app notification inbox

---

## Phase 8 — Flutter UI / Feed Experience — **redesigned 2026-09-06 ("Ink")**

- [x] Design system: tokens, type (Newsreader / DM Sans / JetBrains Mono), spacing, primitives (`core/widgets/ink_widgets.dart`)
- [x] Splash, 2-step onboarding, sign-in with guest path
- [x] Feed: masthead with collector status, hero + ranked rows, skeletons, empty/error states, pull-to-refresh
- [x] Article: lede, key points, why-it-matters, tags, related repos, discussions, source CTA, save/share
- [x] Discover (real topics/repos/funding), Search, Inbox (real, derived), Profile (interests sheet), Saved, Settings
- [x] Local persistence for saves/reads/interests/notification mode
- [ ] Android device pass (fonts load, image CORS is web-only, push permission prompt)
- [ ] iOS: register Firebase app, Notification Service Extension for images
- [ ] Firebase **web** app registration so Google sign-in works in Chrome (guest path works now)
- [ ] "New since you last opened" divider in the feed
- [ ] Sign-in → sync saved ids/interests to backend `/auth/me` (currently device-local)
- [ ] Discussions: HN comment fetch for enriched stories (schema exists, collector doesn't fill it yet)
- [ ] App icon + splash asset for Android/iOS (wordmark-based, no bolt)
- [ ] Review `PRIVACY.md` / `TERMS.md` drafts, host them (launch gate)

---

## Phase 9 — Caching & Performance

### 9.1 Backend
- [ ] Redis caching for feed (per user, 5min TTL)
- [ ] Redis caching for trending lists
- [ ] API response compression (gzip)
- [ ] Database indexes on common queries

### 9.2 Flutter
- [ ] Hive local DB for offline-first feed
- [ ] Image caching (`cached_network_image`)
- [ ] Optimistic UI updates

---

## Phase 10 — Analytics & Monitoring

- [ ] PostHog SDK in Flutter
- [ ] PostHog event tracking (feed_view, article_open, save, share, notification_click)
- [ ] Firebase Crashlytics setup
- [ ] Firebase Analytics events
- [ ] Backend: Prometheus metrics endpoint
- [ ] Backend: Grafana dashboards
- [ ] Backend: Loki log aggregation
- [ ] Sentry for backend error tracking

---

## Phase 11 — Search Infrastructure

- [ ] Typesense deployment
- [ ] Article indexing pipeline (sync from MongoDB → Typesense)
- [ ] Search API endpoint
- [ ] Faceted filters (topic, source, date)
- [ ] Autocomplete / instant search

---

## Phase 12 — Monetization (Post-MVP)

- [ ] Stripe / RevenueCat integration
- [ ] Free tier limits enforcement
- [ ] Premium subscription flow
- [ ] Paywall screens
- [ ] Deep research mode (premium-only)
- [ ] Unlimited tracking (premium-only)

---

## Phase 13 — Deployment & CI/CD

- [ ] Dockerfile for backend
- [ ] `docker-compose.yml` for local dev (API + Redis + MongoDB + Worker)
- [ ] GitHub Actions: backend test + lint + build + deploy
- [ ] GitHub Actions: Flutter test + build (Android APK, iOS IPA)
- [ ] Deploy backend to Render/Railway
- [ ] Android build → Google Play internal track
- [ ] iOS build → TestFlight
- [ ] Production env config (secrets via platform env vars)

---

## Phase 14 — Security & Hardening

- [ ] API rate limiting (per user + per IP)
- [ ] Input validation (Pydantic)
- [ ] CORS lockdown to known origins
- [ ] HTTPS-only enforcement
- [ ] Secret rotation policy
- [ ] Scraping behind proxy / Cloudflare workers
- [ ] App: certificate pinning
- [ ] App: obfuscation (`flutter build --obfuscate`)

---

## Phase 15 — Testing

- [ ] Backend unit tests (pytest)
- [ ] Backend integration tests
- [ ] Flutter widget tests
- [ ] Flutter integration tests (`integration_test`)
- [ ] End-to-end smoke tests
- [ ] Load testing for backend (Locust / k6)

---

## Build Order Recommendation

1. **Foundations** (Phase 0) — get scaffolds running locally
2. **Auth + Onboarding** (Phase 1) — users can sign in & set interests
3. **One scraper** (Phase 2 — start with Hacker News + RSS) → store in MongoDB
4. **AI summarization** (Phase 3.1) → wire summaries into stored articles
5. **Basic feed API + Flutter feed UI** (Phase 6.1 + Phase 8.1–8.2) — end-to-end MVP loop visible
6. **Notifications** (Phase 7) — daily digest first, instant later
7. **Expand scrapers** (Reddit → GitHub → X → Product Hunt → AI blogs)
8. **GitHub intelligence** (Phase 4)
9. **Social intelligence** (Phase 5)
10. **Discover/Trends + Search** (Phase 8.4, 8.5, Phase 11)
11. **Analytics + Monitoring** (Phase 10)
12. **Deployment + CI/CD** (Phase 13)
13. **Hardening + Testing** (Phase 14, 15)
14. **Monetization** (Phase 12)
