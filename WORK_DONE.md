# Work Done — AI Tech Intelligence Platform

> Living log of completed work. Updated as the project progresses.
> Format: `[YYYY-MM-DD] — Phase X.Y — Description` + linked files where relevant.

---

## Sprint 12 — More sources: YouTube, Bluesky, dev communities (2026-09-09)

- YouTube: 12 channels via keyless Atom feeds (`YOUTUBE_CHANNELS`, ids verified live against feed titles; several handle lookups first returned secondary channels like "Theo Rants" and "Lex Clips", so ids are pinned, not resolved at runtime). 3 latest videos per channel, thumbnail as image. `SourceType.youtube`.
- Bluesky: 13 accounts via the public AT Protocol API, no auth (`BLUESKY_ACCOUNTS`, handles verified; note `howard.fm` is Jeremy Howard, `jeremyphoward` is a parody). Only posts carrying an external link become stories; likes+reposts feed the provisional score. `backend/app/services/scrapers/bluesky.py`, `SourceType.bluesky`.
- Feeds added: Lobste.rs, dev.to, TLDR AI, Claude Code releases. Rejected after live test: The Batch, Ben's Bites, Cursor changelog, Anthropic RSS (all 404 or empty).
- Reddit: re-tested. JSON endpoint 403, HTML is the throttling interstitial (as the user's reddit.py documents; that module depends on Zyte, a paid renderer). RSS stays. Official API is the clean fix and needs a client id + secret from the user.
- Flutter: `ArticleSourceType` gains youtube/bluesky; brand marks for Lobste.rs, dev.to, Claude Code.
- Dry run: 37 Bluesky linked posts, 36 videos, all with images. Total sources now 65.
- Reddit via Zyte (user supplied key): `scrapers/reddit.py` renders each subreddit top page with `browserHtml`, parses `<shreddit-post>` attributes (title, score, comments, link, timestamp, image). 12 posts per subreddit, RSS reddit feeds skipped when the key is present, automatic RSS fallback otherwise. Verified: 100 posts per render, scores 50–94. Instagram (activeprogrammer) tested through RSS bridges and Instagram's endpoint: all blocked, needs Graph API approval.

## Sprint 11 — Pop-art editorial redesign (2026-09-08)

User supplied three mockups plus a transparent splash illustration (`techinews_imgs/`) and a full brief: "Apple News meets an editorial magazine meets pop-art illustration", exact colour tokens, display font for headlines, clean sans for body, handwriting only for annotations.

- Tokens: canvas `#080D1A`, surfaces `#111827`/`#171F32`, text `#F8FAFC`/`#9AA6BA`, blue `#2495FF`, pink, yellow, green, purple, orange, cyan; `AppColors.hue(label)` gives a stable hue per topic.
- Type: Shantell Sans 800 headlines, DM Sans body/UI/meta, Kalam only for stickers and annotations (`AppTypography.hand`).
- New `lib/core/widgets/doodles.dart`: Spark, SpeedLines, Scribble underline, DoodleArrow, Sticker, StickyNote, PopCard (hue outline + glow), HueTag pill, PopBookmark (spark burst, reduced-motion aware), Wordmark.
- Card system in `feed_card.dart`: StoryHero (A), TypeCard (B, image-less), StoryRow (C), TrendingCard (D), BreakingCard (E, score ≥90 and <6h).
- Feed: wordmark + handwritten motto + bell, outlined search, sticker tabs incl. Companies, "Hot now" with flame + scribble, breaking card, carousel, hue hashtag topics, GitHub section with sparks, Latest mixes rows and type cards.
- Splash: the provided illustration, "Already a user? Sign in", Get started with doodle arrow, Log back in. Wide layout side-by-side.
- Onboarding: back, 3-segment progress, Skip, two-tone headline with pink scribble, sticky note, hue tiles with glow + check + bounce, CTA fills as picks land. Added Hardware to interests.
- Article: category sticker on hero, reading time, "From the story" paragraphs cleaned from extracted body, hue hashtags, Related stories as a horizontal strip.
- Discover: nine magazine section cards with hue outlines and live counts; repos and funding below. Saved: drawn empty state. Shell: 22px icons, blue scribble under the active tab, content capped at 760px on wide screens.
- Fixed: Material shape+radius assertion on selection, bottom bar expanding to full height, stale web bundle during verification.
- Verified in Chrome 390×844 with taps: splash, onboarding selection, feed, article, discover, saved.
- Open Doodles (CC0) added: 9 SVGs extracted from the `react-open-doodles` npm package into `assets/illustrations/`, rendered by `DoodleFigure` (flutter_svg, recoloured per hue at load). Used on saved/feed/inbox/search/article empty states, sign-in, paywall, and the end of the feed. Kitbitz/unDraw need manual downloads (no public package), not wired.
- Applied the three docs in `~/Downloads/techinews_imgs/` (asset rules, resources, redesign prompt): Phosphor is now the single icon family (`lib/core/theme/app_icons.dart`, semantic names, `phosphor_flutter`), Simple Icons brand marks for recognised sources in `SourceAvatar` (cdn.simpleicons.org, white), assets renamed descriptively (`doodle-*.svg`, `illustration-splash-hero.png`), `ASSET_CREDITS.md` added. Web-only items in those docs (shadcn, Tailwind, Motion) do not apply to Flutter.

## Sprint 10 — "Night" redesign after the Artics reference (2026-09-08)

User pointed at the Artics News App shot (Dribbble) and Newsadoo (Refero) and asked for the UI to match. Structure and mood adopted; two reference details dropped for house rules (fire emoji became an icon, pill chips became r=8 squares).

- Tokens: navy canvas `#0E1320`, blue accent `#3B86F7`, ember `#F2994A` only for trend marks; radii 8/12/16. Fonts: Plus Jakarta Sans bold headlines, DM Sans everywhere else. `serif()`/`mono()` method names kept so no call-site sweep.
- Primitives added to `ink_widgets.dart`: `SourceAvatar`, `TrendBadge`, `StatRow`, `SearchBarButton`, `TabStrip`; `InkImage(quiet:)`.
- Feed: avatar + search + bell masthead, lens tabs (Top stories / Trending / Open source / Research, client-side), "Hot now" carousel of `TrendingCard`s with "Trending N" badges, hashtag `Topics` derived from the current page, From GitHub, Latest rows with right-hand thumbnails.
- Article: 300px hero image with round glyph buttons, source row with avatar + Follow (adds source to Pro topic alerts, paywall for free), numbered key points, hashtag chips linking to search.
- Splash: drawn signal globe (CustomPainter), "Your hourly digest", Get started / Log back in, tappable Terms and Privacy. Returning readers skip straight to the feed in under a second.
- Onboarding: one step, 2-column topic tiles with check badges, "Pick N more" button until three are chosen.
- Shell: Home / Discover / Saved / Account (Saved moved into the shell at `/saved`; Inbox now behind the bell at `/notifications` with a back button). Discover: "Latest topics" tiles.
- Copy: every all-caps kicker converted to sentence case; short time forms lowercased (2d, 3h).
- Verified in Chrome at 400×860: splash, onboarding, feed, article, discover. Analyzer clean. Servers killed after.

## Sprint 9 — Shipaton infrastructure (2026-09-08)

- RevenueCat catalog created via REST API v2 (entitlement `pro`, `pro_monthly` P1M, `pro_annual` P1Y, offering `default` current, packages linked). Test Store key in Flutter `.env`.
- Topic alerts (Pro): Settings section, `topicAlertsProvider`, persisted in `LocalStore` (device-only until account sync).
- Push job `backend/scripts/send_pushes.py`: instant (≥85, last 3 h, max 2/run), daily digest at the 08:07 IST run, weekly on Sundays; FCM image + deep-link data; `pushes` collection prevents double sends. Added as second step of the hourly workflow (cron moved to :37).
- Firebase Admin accepts `FIREBASE_CREDENTIALS_JSON` (env) for Render/Actions. FCM multicast carries `image`.
- `render.yaml` blueprint (free tier, Singapore, health check, secrets as sync:false). Dockerfile copies `scripts/`.
- `README.md` rewritten for judges; `backend/.env.example` generated.
- Verified: push job dry run (correctly nothing to send — no run since Sep 6 because Actions secrets are not set). `flutter analyze` clean.

---

## Sprint 8 — Feed quality, images, RevenueCat Pro (2026-09-06, Shipaton track)

- Ranking: buzz decays with a 36 h half-life; whole-word hot terms; aggregator items with no tech signal get 0.72× base; equal lab weights.
- Clustering (`ranking.cluster`): same story across sources within 96 h → lead gets `coverage`, `related_ids`, +4/source boost; primary sources preferred as lead. Astra now one lead story ×6.
- Pipeline: `rescore_recent()` every run re-ranks the 10-day window (decay + clusters) and backfills 40 images/run; stats add `images_recovered`, `rescored`.
- Images: GitHub OG cards (`opengraph.githubassets.com`), image-only OG pass; feed-window missing images 49% → 21%.
- RSS: release feeds drop branch/CI tags; "Quoting …" posts skipped.
- Flutter: `Article.coverage/relatedIds`; typographic fallback tile (`InkImage.label`); paginated `feedStateProvider` with infinite scroll; "From GitHub" section; "Also covered by" block; coverage badge in kickers.
- RevenueCat: `lib/services/pro.dart` (configure from `REVENUECAT_API_KEY`, entitlement `pro`, purchase/restore/logIn, graceful `unavailable` on web); `features/pro/presentation/paywall_screen.dart` at `/pro`; gates: Instant alerts, free save cap 10; Profile shows Pro row + save count.
- Docs: Phase S plan in WORK_TO_BE_DONE. `flutter analyze` clean. Not yet visually verified after this sprint (servers kept off per user).

---

## Sprint 7 — "Ink" redesign + real data everywhere (2026-09-06)

**Design system** (replaces warm-cream/Inter/pill system; house rules from `CLAUDE_DESIGN copy.md` §A applied)
- Tokens: charcoal canvas `#0C0E12`, one amber accent `#E8843C`, three ink levels, hairlines instead of card borders (`app_colors.dart`, `app_spacing.dart`)
- Type: Newsreader (serif headlines) / DM Sans (UI) / JetBrains Mono (all metadata) via google_fonts (`app_typography.dart`)
- Rectangular buttons (radius 10), square mono chips, four-tab nav (Feed · Discover · Inbox · You). Search moved under Discover.
- New primitives: `core/widgets/ink_widgets.dart` (MetaLine, SectionHeader, LiveDot, EmptyState, ScoreMark, GutterDivider, InkImage), skeletons matching row shapes.
- Removed: ambient gradient background, bolt-in-rounded-square logo, three-icon onboarding row, em dashes in copy.

**Screens rewritten:** splash (wordmark + hairline draw, <1.2 s), onboarding (2 steps), sign-in (inline error, guest path), feed (masthead with "Updated · next run · +N new", hero + ranked rows + Earlier), article (lede, numbered key points, why-it-matters, repo cards, source CTA), discover (rising topics / repos / funding), search (debounced, suggestions), inbox, profile (interests sheet), saved, settings (notification mode, how-the-feed-is-built, legal links).

**Data / persistence**
- `data/local/local_store.dart` (SharedPreferences): saved ids + cached article JSON, read ids, guest interests, notification mode, onboarding flag, read-notification ids. Provided via `localStoreProvider` override in `main.dart`.
- `savedIdsProvider` for instant toggle; `feedMetaProvider` reads `/articles/meta`.
- Discover + Inbox now real: `ApiTrendsRepository`, `ApiNotificationsRepository` (mocks only when `USE_MOCK_DATA=true`).

**Backend**
- `trends_service.py` derives topics (7d vs prior 7d), repos, funding from Mongo. `$top` picks the best sample headline.
- New `GET /api/v1/notifications` (breaking ≥85 / daily 08:00 IST digest / github / funding, all from stored stories).
- New `GET /api/v1/articles/meta`; pipeline writes `meta.pipeline` {last_run, next_run, added…}. Cron now **hourly** (repo is public → unlimited Actions minutes).
- GitHub collector: explicit-content blocklist.

**Verified (Playwright, 400×860):** onboarding, feed, discover, inbox, profile, article, settings render; save → reload → Saved list ✅; interests sheet → 2 topics persisted ✅; weekly digest persisted ✅. `flutter analyze` clean. Android build not run this session (Mac only).

**Added:** `PRIVACY.md`, `TERMS.md` drafts (linked from Settings; launch-gate items).

---

## Sprint 6 — Sourcing v2 + infra restore (2026-09-05 → 06)

**Council decision** (llm-council skill, run inline): drop scraper sprawl and VM "agents"; keyless structured feeds + LLM on ranked top-N + GitHub Actions cron. Rationale in WORK_TO_BE_DONE §Phase 2.

**Infra restored after ~70 days idle**
- MongoDB Atlas M0 recreated (same host/user/password → existing `MONGO_URI` works). Redis Cloud DB deleted by provider; **deferred** — cache is already best-effort (`redis_cache.py`), Celery removed.
- New free services wired + verified: GitHub fine-grained read token (5k req/h), Cloudflare Workers AI (FLUX.1-schnell test image OK), Supabase Storage bucket `images` (public read OK). Reddit app + HF token dropped (not needed).

**Backend**
- `app/services/sources.py` — 25 feeds + 12 release repos + hot-term vocab
- `app/services/scrapers/{rss,github_trending,arxiv,huggingface,html_list}.py` — new collectors
- `app/services/ranking.py` — score / dedup / diversify; `extract.py` — trafilatura→Jina→Firecrawl; `images.py` — OG→generated→Supabase
- `app/services/pipeline.py` rewritten: collect → rank → enrich top-N → store all; stats include `unique_vs_hn`
- `article_repo.feed_candidates` now 10-day window, trend_score desc
- `scripts/run_pipeline.py` — `--dry-run` (no LLM, no writes) / `--limit`
- `.github/workflows/collect.yml` — cron every 3h
- Removed: `app/workers/`, celery + praw deps, NewsAPI from discovery. Added: `feedparser`, `trafilatura`.
- Schema: `SourceType.arxiv`, `SourceType.huggingface`. Config: `HF_TOKEN`, `CLOUDFLARE_*`, `SUPABASE_*`.

**Verified runs**
- Dry run: ~500 items from 40 sources (Anthropic 8, Meta AI 8, GitHub 35, HN 29, arXiv 25, HF 34, …)
- Real run `--limit 5`: 466 stored, 5 enriched via Gemini, 5/5 unique vs HN, 50 s. API `/health` mongo=true, feed serves.

**Flutter**
- `.env` `API_BASE_URL` → `http://localhost:8000` for Chrome testing (Mac; phone unavailable). Firebase web not configured → guest path.

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

## Sprint 3 — Infrastructure connected (2026-06-27)

The four 🔴 infra blockers are now live and verified against the real backend. This unlocks Phases 1, 7, 9, 13.

- **MongoDB Atlas** ✅ — free M0 cluster `Cluster0` (project `techinews`, Mumbai). `MONGO_URI` in `backend/.env`. Verified: `ping` ok, Mongo 8.0. DB `techinews` will materialize on first write.
- **Redis Cloud** ✅ — free 30 MB DB `techinews` (Mumbai). `REDIS_URL` + both Celery URLs point at it (free tier = single logical DB, so cache + broker + results share it for now). Verified: ping + set/get, Redis 8.4.
- **Firebase** ✅ — project `techinews-d7720` (Spark/free). Android app registered as `com.techinews.app`. Two files placed + gitignored: `android/app/google-services.json` (Flutter) and `backend/secrets/firebase-admin.json` (Admin SDK). Verified: `firebase_admin.initialize_app` succeeds, `messaging.send` + `auth.verify_id_token` reachable.
- **GitHub repo** ✅ — pushed to [github.com/aryanchauhanoffical/techinews](https://github.com/aryanchauhanoffical/techinews), branch `main`, 220 files. Initial commit excludes all secrets.
- **Secret hygiene:** GitHub push-protection caught live keys in `everyapi.md` → file removed from tracking + gitignored (keys already safely in `backend/.env`). Confirmed `.env`, `secrets/`, `firebase-admin.json`, `google-services.json` all untracked.
- New backend deps installed in `.venv`: `pymongo[srv]`/`dnspython`, `redis`, `firebase-admin`.
- ⚠️ **Pending rotation** (all exposed in chat during setup): Mongo DB password, Redis password, GitHub PAT (revoke now — push is done).

---

## Sprint 4 — Backend made real: persistence + cache + auth + FCM (2026-06-27)

Turned the connected infra into working features. All verified against the live services.

### Phase 9.1 — MongoDB persistence (replaces in-memory store)
- [backend/app/core/ids.py](backend/app/core/ids.py) — `make_article_id()`: deterministic MD5-based IDs. Fixes the old `hash(url)` bug (salted per-process → IDs changed every restart, breaking `/articles/{id}`). [newsapi.py](backend/app/services/scrapers/newsapi.py) now uses it.
- [backend/app/db/mongo.py](backend/app/db/mongo.py) — Motor async client, best-effort `connect()` (ping-verified), index setup, graceful close. Falls back to in-memory if Mongo down.
- [backend/app/services/article_repo.py](backend/app/services/article_repo.py) — Mongo-backed `ArticleRepository` (singleton `articles`). Upsert on deterministic `_id` (idempotent), `feed_candidates()` (trend-filtered + chrono via Mongo), `get`, `search` (regex), `count`, `existing_ids`. In-memory fallback throughout.
- Indexes created: `url` (unique), `published_at -1`, `trend_score -1`, `topics`.
- [pipeline.py](backend/app/services/pipeline.py) + [feed_service.py](backend/app/services/feed_service.py) + [admin.py](backend/app/api/v1/admin.py) refactored off the deleted `STORE` onto the repo.

### Phase 9.1 — Redis caching
- [backend/app/db/redis_cache.py](backend/app/db/redis_cache.py) — async helpers (`get_json`/`set_json`/`clear_prefix`), best-effort (no-op if Redis down). Feed pages cached 5-min TTL, keyed by page/size/min_trend/interests. Pipeline clears `feed:*` on new articles.

### Phase 1.1 — Firebase auth (backend)
- [backend/app/services/firebase.py](backend/app/services/firebase.py) — Admin SDK init + `verify_id_token`. Best-effort: dev-user fallback when creds absent.
- [backend/app/db/users_repo.py](backend/app/db/users_repo.py) — Mongo user store keyed by Firebase `uid`; `upsert_from_firebase`, profile update, `set_fcm_token`.
- [backend/app/core/deps.py](backend/app/core/deps.py) — `get_current_user` dependency (Bearer token → verify → upsert).
- [auth.py](backend/app/api/v1/auth.py) rewritten: `/verify`, `/me`, PATCH `/me`, `/fcm-token` now real (Mongo-backed, token-gated).

### Phase 7.1 — FCM push (backend)
- [backend/app/services/notifications.py](backend/app/services/notifications.py) — `send_to_token` / `send_to_tokens` (multicast). Admin `POST /admin/fcm/test?token=` for device testing.

### main.py
- [main.py](backend/app/main.py) lifespan now connects Mongo + Redis + Firebase on boot, closes on shutdown. `/health` reports `mongo`/`redis`/`firebase` booleans.

### Verified end-to-end (live services)
- `/health` → `{mongo:true, redis:true, firebase:true}`.
- Pipeline run → 8 articles persisted to MongoDB `techinews.articles` (direct driver count confirms; all 5 indexes present).
- **Persistence proven:** store held **16 articles across a full server restart** with no re-run (in-memory would reset to 0).
- Caching: 2nd feed call ~3× faster; `feed:0:3:30:` key present in Redis.
- Auth enforced: `/auth/me` no-token → 401, `/auth/verify` bad-token → 401 (Firebase live).
- New venv deps: `motor`.

---

## Sprint 5 — Flutter Firebase wiring (2026-06-27)

Connected the Flutter app to the live Firebase project + authenticated backend.

### Phase 0 / Android config
- **Fixed package-name mismatch:** Android `applicationId` was `com.example.techinews` but the Firebase app is `com.techinews.app`. Set `applicationId = "com.techinews.app"` in [android/app/build.gradle.kts](android/app/build.gradle.kts) so `google-services.json` matches. Bumped `minSdk` to ≥23 (Firebase Auth requirement).
- Applied the **google-services Gradle plugin**: declared in [android/settings.gradle.kts](android/settings.gradle.kts) (`4.4.2 apply false`) + applied in the app module.
- Enabled Firebase packages in [pubspec.yaml](pubspec.yaml): `firebase_core`, `firebase_auth`, `firebase_messaging`, `google_sign_in` (analytics/crashlytics/apple still commented). `flutter pub get` → +16 deps.

### Phase 1.2 — real auth (Flutter)
- [lib/main.dart](lib/main.dart) — `Firebase.initializeApp()` on boot (Android reads google-services.json natively; wrapped in try/catch so desktop/web degrade to mock).
- [lib/data/repositories/firebase_auth_repository.dart](lib/data/repositories/firebase_auth_repository.dart) — real `AuthRepository`: Google sign-in → Firebase credential → POST ID token to `/auth/verify` (creates Mongo user) → returns backend profile. `updateProfile` PATCHes `/auth/me`. Apple/GitHub stubbed ("coming soon"); email → anonymous session for now.
- [lib/core/network/api_client.dart](lib/core/network/api_client.dart) — Dio interceptor attaches `Authorization: Bearer <Firebase ID token>` to every request (safe no-op when signed out).
- [lib/services/providers.dart](lib/services/providers.dart) — `authRepositoryProvider` uses `FirebaseAuthRepository` when Firebase is initialized + not mock mode, else `MockAuthRepository`.

### Phase 7.2 — FCM (Flutter)
- `firebase_auth_repository` registers the device FCM token on sign-in (`requestPermission` → `getToken` → POST `/auth/fcm-token`).

### Verified
- `flutter analyze` → **0 errors, 0 warnings** (30 pre-existing info lints unchanged). New files clean.
- **Android debug APK built successfully** (`build/app/outputs/flutter-apk/app-debug.apk`, 154 MB) — proves the google-services Gradle wiring, package match, and Firebase SDK linkage are all correct.
- Debug SHA-1 added to Firebase by user: `61:AB:15:43:93:E6:B3:E0:33:97:D1:8C:A1:BC:FC:76:15:F8:73:74`.
- **Google sign-in provider enabled** in Firebase Auth; `google-services.json` re-downloaded and swapped in — now contains both OAuth clients (Android type-1 w/ SHA-1 + Web type-3 for ID tokens). Verified.
- ⚠️ **Not yet runtime-tested** on a device/emulator. Note for the test: the Android emulator can't reach `127.0.0.1:8000` — `API_BASE_URL` in the Flutter `.env` must be `http://10.0.2.2:8000` (emulator→host) or the host LAN IP (physical device). Backend must be running.

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
