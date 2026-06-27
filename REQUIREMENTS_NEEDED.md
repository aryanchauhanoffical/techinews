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
| **NewsAPI.org key** | 🔴 Blocker | Article discovery / headlines | ✅ provided |
| **Firecrawl API key** | 🔴 Blocker | Article extraction fallback (JS-heavy sites) | ✅ provided |
| **Jina Reader API key** | 🔴 Blocker | Primary article extraction (markdown from any URL) | ✅ provided |
| OpenAI API Key | 🟡 Mid | Optional second summarizer / embeddings | ☐ (skipped — Cloudflare path didn't pan out) |
| Anthropic Claude API Key | 🟡 Mid | Optional higher-quality summaries | ☐ (skipped — Cloudflare path didn't pan out) |
| Preferred default model | ✅ | Locked to `gemini-2.5-flash` | ✅ |

**Notes on the failed Cloudflare route** (see `everyapi.md`): the 6 `cfut_…` tokens for Claude/OpenAI/Grok/Alibaba via Cloudflare were tested via a deployed Worker. They authenticated successfully (verify endpoint returned `success: true`) but every model call returned `error 2021: Invalid User Credentials`. Those models are **3rd-party partner models** — they need either Workers AI Paid billing or AI Gateway BYOK. Path abandoned per your decision. Worker code and all CF env vars removed from repo.

---

## 2. Scraping APIs / Services

| Item | Priority | Why | Status |
|---|---|---|---|
| **NewsAPI.org** | 🔴 Blocker | Headlines discovery | ✅ provided |
| **Jina Reader** | 🔴 Blocker | Clean markdown extraction | ✅ provided |
| **Firecrawl** | 🔴 Blocker | JS-rendered fallback | ✅ provided |
| **Hacker News** — no key needed (public Algolia API) | ✅ | Free | ✅ |
| **Apify API Token** + chosen actors | 🟠 Soon | X/Twitter scraping, advanced sites | ☐ |
| **Reddit App credentials** (client_id, client_secret, user_agent) via PRAW | 🟠 Soon | Reddit post + discussion fetching | ☐ |
| **GitHub Personal Access Token** (classic, with `public_repo` + `read:org`) | 🟠 Soon | GitHub REST/GraphQL — repos, trending, stars | ☐ |
| **Product Hunt API Token** | 🟡 Mid | Product launches feed | ☐ |
| **X / Twitter API access** — confirm path: official paid API ($100/mo Basic) **or** Apify actor only? | 🟠 Soon | Decision needed before X integration | ☐ |
| Proxy/residential IP service (BrightData, Smartproxy, Oxylabs) for heavy scraping | 🟡 Mid | Avoid IP bans on aggressive scrapers | ☐ |

---

## 3. Firebase / Google Cloud

| Item | Priority | Why | Status |
|---|---|---|---|
| **Firebase project created** (note project ID) | 🔴 Blocker | Auth + FCM + Crashlytics + Analytics | ☐ |
| `google-services.json` (Android) | 🔴 Blocker | Firebase Android config | ☐ |
| `GoogleService-Info.plist` (iOS) | 🔴 Blocker | Firebase iOS config | ☐ |
| **Firebase Admin SDK service account JSON** | 🔴 Blocker | Backend → FCM send + token verify | ☐ |
| Enable Sign-in providers: Google, Apple, GitHub, Email | 🟠 Soon | Auth flows | ☐ |
| **Apple Developer account** ($99/yr) + Apple Sign-In Service ID + key | 🟠 Soon | iOS Apple Sign-In | ☐ |
| **GitHub OAuth App** (client_id + client_secret) | 🟠 Soon | GitHub login | ☐ |

---

## 4. Databases & Cache

| Item | Priority | Why | Status |
|---|---|---|---|
| **MongoDB Atlas cluster** — connection string (SRV URI) | 🔴 Blocker | Primary datastore | ☐ |
| MongoDB Atlas — IP whitelist permission (allow 0.0.0.0/0 during dev) | 🔴 Blocker | Local dev access | ☐ |
| **Redis Cloud / Upstash** — connection URL + password | 🔴 Blocker | Cache + Celery broker | ☐ |
| **Typesense Cloud** (or self-hosted) API key + host | 🟡 Mid | Search infrastructure | ☐ |
| **PostgreSQL** instance _(Phase 2 / future)_ | 🟢 Late | Analytics & reporting | ☐ |

---

## 5. Hosting & Infrastructure

| Item | Priority | Why | Status |
|---|---|---|---|
| **Render or Railway account** + linked GitHub | 🟠 Soon | Backend hosting | ☐ |
| **Cloudflare account** + domain you own | 🟡 Mid | CDN, DDoS, edge cache | ☐ |
| **Domain name** for the platform | 🟡 Mid | API subdomain + web landing | ☐ |
| **GitHub repository** (private) for codebase | 🔴 Blocker | Source control + CI/CD | ☐ |
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
