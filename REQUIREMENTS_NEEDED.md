# Requirements Needed From You

> Everything you need to provide before / during the build. Group by phase so you can hand things over when each phase starts.
> Mark each as ✅ once provided. Send keys via a secure channel; I'll add them to `.env` files (never committed).

---

## Legend
- 🔴 **Blocker** — build cannot start without this
- 🟠 **Soon** — needed within the first 1–2 phases
- 🟡 **Mid-build** — needed mid-project
- 🟢 **Late** — needed near production launch

---

## 1. AI / LLM Providers

| Item | Priority | Why | Status |
|---|---|---|---|
| **Google Gemini API Key** (`gemini-2.5-flash`) | 🔴 Blocker | Article summarization, key points, why-it-matters, tagging | ✅ provided — **free tier quota hit during dev** (resets in 24h). Upgrade to billing-enabled tier removes the 250K-token/day cap. |
| ~~NewsAPI.org key~~ | — | replaced by feeds (v2) | ❌ removed |
| **Firecrawl API key** | 🔴 Blocker | Article extraction fallback (JS-heavy sites) | ✅ provided |
| **Jina Reader API key** | 🔴 Blocker | Primary article extraction (markdown from any URL) | ✅ provided |
| OpenAI API Key | 🟡 Mid | Optional second summarizer / embeddings | ☐ (skipped — Cloudflare path didn't pan out) |
| Anthropic Claude API Key | 🟡 Mid | Optional higher-quality summaries | ☐ (skipped — Cloudflare path didn't pan out) |
| Preferred default model | ✅ | Locked to `gemini-2.5-flash` | ✅ |

**Notes on the failed Cloudflare route** (see `everyapi.md`): the 6 `cfut_…` tokens for Claude/OpenAI/Grok/Alibaba via Cloudflare were tested via a deployed Worker. They authenticated successfully (verify endpoint returned `success: true`) but every model call returned `error 2021: Invalid User Credentials`. Those models are **3rd-party partner models** — they need either Workers AI Paid billing or AI Gateway BYOK. Path abandoned per your decision. Worker code and all CF env vars removed from repo.

---

## 2. Sources / Scraping (v2 — 2026-09-05)

| Item | Priority | Why | Status |
|---|---|---|---|
| **RSS / Atom feeds, HN Algolia, arXiv API, GitHub release feeds, subreddit `.rss`** | ✅ | Primary discovery, keyless | ✅ live |
| **GitHub fine-grained token** (public repos, read-only) | ✅ | GitHub search 5k req/h | ✅ in `backend/.env` |
| **Jina Reader** / **Firecrawl** | 🟡 fallback | Extraction fallbacks behind local trafilatura | ✅ provided |
| Hugging Face read token (`HF_TOKEN`) | 🟢 optional | Higher rate limit only | ☐ skipped (keyless works) |
| ~~NewsAPI~~ | — | dev-only licence, 24h delay | ❌ removed from pipeline |
| ~~Reddit Data API app~~ | — | approval flow is moderation-only | ❌ dropped → subreddit RSS |
| ~~Apify / X API / proxies~~ | — | Not needed under v2 strategy | ❌ dropped |
| Product Hunt API token | 🟢 optional | RSS already used | ☐ |

### Images for notifications (free)
| Item | Status |
|---|---|
| **Cloudflare Workers AI** (`CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_API_TOKEN`; FLUX.1-schnell) | ✅ verified |
| **Supabase Storage** (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, bucket `images`, public) | ✅ verified |
| Cloudflare R2 | ❌ skipped (needs card on file) |

### GitHub Actions secrets — **user action, still needed**
Repo → Settings → Secrets and variables → Actions → New repository secret. Copy values from `backend/.env`:
`MONGO_URI`, `GEMINI_API_KEY`, `GH_READ_TOKEN` (= GITHUB_TOKEN value; GitHub reserves the name), `JINA_API_KEY`, `FIRECRAWL_API_KEY`, `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_API_TOKEN`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`. `REDIS_URL` optional.

---

## 3. Firebase / Google Cloud

| Item | Priority | Why | Status |
|---|---|---|---|
| **Firebase project created** (note project ID) | 🔴 Blocker | Auth + FCM + Crashlytics + Analytics | ✅ `techinews-d7720` (Spark/free) |
| `google-services.json` (Android) | 🔴 Blocker | Firebase Android config | ✅ placed at `android/app/` (pkg `com.techinews.app`) |
| `GoogleService-Info.plist` (iOS) | 🔴 Blocker | Firebase iOS config | ☐ (iOS app not registered yet — Android-first) |
| **Firebase Admin SDK service account JSON** | 🔴 Blocker | Backend → FCM send + token verify | ✅ `backend/secrets/firebase-admin.json`, verified |
| Enable Sign-in providers: Google, Apple, GitHub, Email | 🟠 Soon | Auth flows | ☐ |
| **Apple Developer account** ($99/yr) + Apple Sign-In Service ID + key | 🟠 Soon | iOS Apple Sign-In | ☐ |
| **GitHub OAuth App** (client_id + client_secret) | 🟠 Soon | GitHub login | ☐ |

---

## 4. Databases & Cache

| Item | Priority | Why | Status |
|---|---|---|---|
| **MongoDB Atlas cluster** — connection string (SRV URI) | 🔴 Blocker | Primary datastore | ✅ `Cluster0`, Mongo 8.0, verified |
| MongoDB Atlas — IP whitelist permission (allow 0.0.0.0/0 during dev) | 🔴 Blocker | Local dev access | ✅ current IP whitelisted (add 0.0.0.0/0 before deploy) |
| Redis Cloud / Upstash — connection URL | 🟢 optional | Feed cache only (best-effort); Celery removed | ☐ deferred 2026-09-05 — provider deleted idle free DB |
| **Typesense Cloud** (or self-hosted) API key + host | 🟡 Mid | Search infrastructure | ☐ |
| **PostgreSQL** instance _(Phase 2 / future)_ | 🟢 Late | Analytics & reporting | ☐ |

---

## 5. Hosting & Infrastructure

| Item | Priority | Why | Status |
|---|---|---|---|
| **Render or Railway account** + linked GitHub | 🟠 Soon | Backend hosting | ☐ |
| **Cloudflare account** + domain you own | 🟡 Mid | CDN, DDoS, edge cache | ☐ |
| **Domain name** for the platform | 🟡 Mid | API subdomain + web landing | ☐ |
| **GitHub repository** (private) for codebase | 🔴 Blocker | Source control + CI/CD | ✅ github.com/aryanchauhanoffical/techinews |
| **GitHub Actions** enabled (free tier OK) | 🟠 Soon | CI/CD pipeline | ☐ |

---

## 6. App Store / Distribution

| Item | Priority | Why | Status |
|---|---|---|---|
| **Google Play Console** account ($25 one-time) | 🟢 Late | Android distribution | ☐ |
| **Apple Developer Program** account ($99/yr) | 🟢 Late | iOS distribution | ☐ |
| App name (final, no conflicts on stores) | 🟠 Soon | Bundle ID, package name | ☐ |
| App icon (1024x1024 PNG) | 🟠 Soon | Branding | ☐ |
| Splash screen design | 🟠 Soon | First impression | ☐ |
| Brand color palette + logo files | 🟠 Soon | Theming | ☐ |
| Privacy Policy URL | 🟢 Late | Store requirement | ☐ |
| Terms of Service URL | 🟢 Late | Store requirement | ☐ |

---

## 7. Analytics & Monitoring

| Item | Priority | Why | Status |
|---|---|---|---|
| **PostHog Cloud** API key + host | 🟡 Mid | Product analytics | ☐ |
| **Sentry DSN** (backend + Flutter) | 🟡 Mid | Error tracking | ☐ |
| **Grafana Cloud** account _(or self-hosted)_ | 🟢 Late | Metrics dashboards | ☐ |

---

## 8. Monetization (Post-MVP)

| Item | Priority | Why | Status |
|---|---|---|---|
| **Stripe** account + API keys | 🟢 Late | Web payments | ☐ |
| **RevenueCat** account + API key | 🟢 Late | Mobile IAP / subscriptions | ☐ |
| Subscription tier pricing decisions | 🟢 Late | Paywall design | ☐ |

---

## 9. Product / Content Decisions Needed From You

| Decision | When | Notes |
|---|---|---|
| Final app name + brand | Phase 0 | Affects every config file |
| Launch markets (India only / global) | Phase 0 | Affects content sources + language |
| Default content language (English only first?) | Phase 0 | Localization later |
| Interest categories — confirm the list in idea.md is complete | Phase 1 | Drives onboarding UX |
| Notification frequency defaults | Phase 7 | User onboarding default |
| Premium feature breakdown (free vs paid) | Phase 12 | Monetization design |
| Tone of AI summaries (neutral / casual / expert)? | Phase 3 | Prompt design |
| Sources to prioritize first (top 5) | Phase 2 | Scraping order |

---

## 10. Optional Assistants / Services To Consider

| Item | Why It Helps |
|---|---|
| **Designer** (or Figma file) | UI mockups for feed, onboarding, profile — speeds Flutter UI build significantly |
| **Copywriter** | App store listing, onboarding microcopy, notification text |
| **DevOps consultant** (later) | When scaling past MVP — Kubernetes, multi-region |
| **Backend engineer** (later) | If scraping/AI pipeline volume grows beyond solo capacity |

---

## How to Hand Things Over

When you have keys ready, you can either:
1. Paste them in our chat **(I'll add them to `.env` and remind you to rotate later)**
2. Drop them in a `.env.local` file in the project root yourself (I'll never commit it — already in `.gitignore`)
3. Use a secrets manager (1Password, Doppler) and share access

**Never commit any keys to git.** A `.env.example` template will be created with placeholder values so the structure is visible without leaking secrets.


## Reddit via Zyte (done 2026-09-09)

User supplied a Zyte API key (saved in `backend/.env` as `ZYTE_API_KEY`). `RedditCollector` renders each subreddit's top page through Zyte once per run (4 renders/hour). Add `ZYTE_API_KEY` to the GitHub Actions secrets. Free trial credit is limited; after it runs out the collector logs a failure and RSS takes over automatically.

## Optional: Reddit official API

Reddit blocks both the JSON endpoint (403) and plain HTML (interstitial) for non-browser clients, so only the RSS feeds work and they throttle after the first one. The clean fix is a free "script" app at https://www.reddit.com/prefs/apps which gives:

- `REDDIT_CLIENT_ID`
- `REDDIT_CLIENT_SECRET`

Add both to `backend/.env` and the Actions secrets. Not needed for the demo; Hacker News, Lobste.rs and Bluesky cover the discussion signal.
