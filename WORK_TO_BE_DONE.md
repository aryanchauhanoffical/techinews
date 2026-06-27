# Work To Be Done — AI Tech Intelligence Platform

> Complete build plan from scratch. The current project is an empty Flutter starter (default counter app). Everything below needs to be built.

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

## Phase 2 — Data Ingestion / Scraping Layer (Backend)

### 2.1 Scraper Services
- [ ] RSS feed ingester (TechCrunch, The Verge, Wired, Ars Technica, Hacker News)
- [ ] Hacker News API integration (top, new, show)
- [ ] Reddit API integration (PRAW) — fetch top posts from r/MachineLearning, r/programming, r/startups, r/technology, r/artificial
- [ ] GitHub Trending scraper (via Firecrawl + GitHub REST API)
- [ ] Product Hunt API integration
- [ ] X/Twitter scraper (via Apify actor)
- [ ] Generic web article scraper (Firecrawl + BeautifulSoup fallback)
- [ ] AI blog scrapers (OpenAI blog, Anthropic blog, Google AI, Meta AI, NVIDIA blog)

### 2.2 Scraping Pipeline
- [ ] Celery worker setup with Redis broker
- [ ] Scheduled scraping jobs (Celery Beat: every 15min / 1h / 6h tiers)
- [ ] Deduplication logic (URL hash + title similarity)
- [ ] Content cleaner (strip HTML, ads, boilerplate)
- [ ] Raw article storage in MongoDB
- [ ] Error handling + retry logic
- [ ] Rate limiter per source

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

## Phase 8 — Flutter UI / Feed Experience

### 8.1 Core Navigation
- [ ] Bottom navigation (Feed, Discover, Notifications, Profile)
- [ ] App theme (light + dark mode)
- [ ] Custom fonts + typography system
- [ ] Color palette + design tokens

### 8.2 Feed Screen (Short-Form / Inshorts-style)
- [ ] Vertical card swipe (PageView.builder)
- [ ] Article card: image, headline, source, AI summary, key points
- [ ] Swipe up = next article
- [ ] Tap = open full article view
- [ ] Save / Share / "Not interested" actions
- [ ] Pull-to-refresh
- [ ] Pagination / infinite scroll

### 8.3 Article Detail Screen
- [ ] Full AI summary
- [ ] "Why it matters" section
- [ ] Related GitHub repos section
- [ ] Reddit discussions section
- [ ] X threads section
- [ ] Read full article (in-app browser via `flutter_inappwebview`)
- [ ] Share + Save buttons

### 8.4 Discover / Trends Screen
- [ ] Trending topics
- [ ] Trending GitHub repos
- [ ] Trending startups
- [ ] Funding announcements
- [ ] Category browser

### 8.5 Search Screen
- [ ] Search bar with semantic search
- [ ] Filters (date, topic, source, company)
- [ ] Search results list

### 8.6 Profile / Settings Screen
- [ ] Edit interests
- [ ] Notification preferences
- [ ] Theme toggle
- [ ] Saved articles
- [ ] Reading history
- [ ] Account / Sign out

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
