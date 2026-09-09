# TechiNews

**The tech news that actually moved today, ranked, summarised, with the repo behind it.**

TechiNews is a mobile reader for developers, founders, and investors. Every hour a collector reads forty structured sources, from lab blogs and Hacker News to GitHub releases and arXiv, clusters the same story across sources, ranks what changed, and writes a thirty-second summary for the top of the feed. When a launch has code, the GitHub repository sits under the headline with stars and language.

Built for the RevenueCat Shipaton 2026, Next Gen category. Flutter app, FastAPI backend, MongoDB, and a GitHub Actions cron. No servers to keep alive.

---

## What it does

| Screen | What you get |
|---|---|
| Feed | Lead story, ranked top stories, a "From GitHub" strip, then everything from the last ten days. A live line shows when the collector last ran and when it runs next. |
| Article | Serif headline, lede, numbered key points, "why it matters", tags, the linked repo, and the same story as covered by other sources. |
| Discover | Rising topics with week-over-week growth, repos worth watching, funding rounds. All derived from stored stories, nothing hand-curated. |
| Inbox | Breaking alerts, the daily digest, GitHub climbers, funding. Derived from real data, read state kept on device. |
| You | Interests that lead the feed, notification cadence, saved stories, Pro. |

## How the feed is built

**Sources are feeds, not scrapers.** RSS and Atom from 25 publications and lab blogs, release feeds for 12 key repos, the Hacker News Algolia API, GitHub search for new repos crossing a star threshold, the arXiv API, Hugging Face daily papers and trending models, plus a listing-page reader for the two labs that publish no feed. Nothing needs a login, nothing violates a terms of service, and the whole collection runs in about a minute on a free GitHub Actions runner.

**Ranking is deterministic and cheap.** Each item gets a static source-quality base, a buzz component from hot-term hits and the engagement the source already exposes, and a freshness bonus. Buzz decays with a 36-hour half-life. The recent window is re-scored every run, so a big story from last week cannot sit above a decent story from this morning.

**Stories are clustered across sources.** Items published within 96 hours that share a named entity or overlapping title tokens become one story. The best-scored item leads, carries a coverage count, and links to the rest. No source gets more than four of the top slots.

**The LLM only touches the top thirty.** Gemini writes the summary, key points, "why it matters", tags, and a significance score for the ranked head of each run. Everything else is stored with its feed summary and still appears further down. This keeps the whole system inside free tiers.

**Images come from three places.** The source's own image, then the page's Open Graph tag, then, for top stories only, a generated illustration from Cloudflare Workers AI stored in Supabase. GitHub repositories use GitHub's own card image. Anything left gets a typographic tile in the app rather than a broken-image glyph.

Success is measured with one number the pipeline prints every run: `unique_vs_hn`, how many surfaced stories are not on the Hacker News front page.

## Monetisation with RevenueCat

Reading stays free. **TechiNews Pro** pays for the collector and the pushes.

| Free | Pro |
|---|---|
| Ranked feed, summaries, Discover, Inbox | Everything in free |
| Daily or weekly digest push | Instant alerts, a push the minute a story scores 85 or higher |
| Ten saved stories | Unlimited saves, kept offline |
| | Topic alerts, follow a company, a repo, or a keyword |

The integration lives in [`lib/services/pro.dart`](lib/services/pro.dart). One entitlement, `pro`, is checked everywhere a gate exists. Packages and prices come from the RevenueCat offering at runtime, so pricing changes need no app release. The paywall is a normal screen in the app's design system ([`lib/features/pro/presentation/paywall_screen.dart`](lib/features/pro/presentation/paywall_screen.dart)), with restore purchases and a graceful "unavailable" state on platforms RevenueCat does not support. Signing in calls `Purchases.logIn` so entitlements follow the account. The catalog was created through RevenueCat's REST API v2 and runs against the Test Store for the demo.

## Technical choices

- **Flutter + Riverpod + go_router.** One codebase, a four-tab shell, feature folders. State lives in providers; screens are thin.
- **A design system, not a theme.** Near-black canvas, one amber accent, Newsreader for headlines, DM Sans for UI, JetBrains Mono for every piece of metadata. Tokens in `lib/core/theme/`, primitives in `lib/core/widgets/ink_widgets.dart`. Rectangular buttons, hairlines instead of bordered cards, designed empty and error states.
- **Local first.** Saves, read state, interests, and notification cadence persist on the device through `LocalStore`. An account is optional and only adds sync.
- **FastAPI + Motor + MongoDB Atlas.** Article documents are the single source of truth. Trends, the inbox, and the feed meta line are all derived queries. Redis is optional and the app degrades without it.
- **GitHub Actions as the scheduler.** [`.github/workflows/collect.yml`](.github/workflows/collect.yml) runs the collector and the push job hourly. The 08:00 IST run sends the daily digest; Sundays add the weekly.
- **Render for the API.** [`render.yaml`](render.yaml) deploys the backend on the free tier with one click.
- **Firebase** for Google sign-in and FCM, with the service account passed as an environment variable on servers.

## Run it

Backend:

```bash
cd backend
python -m venv .venv && .venv/bin/pip install -r requirements.txt
cp .env.example .env          # fill MONGO_URI and GEMINI_API_KEY at minimum
.venv/bin/python scripts/run_pipeline.py --dry-run    # collect + rank, no LLM, no writes
.venv/bin/python scripts/run_pipeline.py --limit 10   # real run
.venv/bin/uvicorn app.main:app --port 8000
```

App:

```bash
flutter pub get
# .env at the repo root: API_BASE_URL=http://localhost:8000, REVENUECAT_API_KEY=<test store key>
flutter run -d chrome --web-port 3000    # web: everything except purchases
flutter run                              # Android: full experience including the paywall
```

## Repository map

```
backend/app/services/sources.py       the source list and hot-term vocabulary
backend/app/services/scrapers/        rss, github_trending, arxiv, huggingface, html_list, hackernews
backend/app/services/ranking.py       score, dedup, cluster, diversify
backend/app/services/pipeline.py      collect → rank → enrich top-N → store → re-score window
backend/app/services/images.py        OG pass, GitHub cards, generation + upload
backend/app/services/trends_service.py  Discover data derived from stored articles
backend/app/api/v1/                   articles, trends, notifications, auth, admin
backend/scripts/                      run_pipeline.py, send_pushes.py
lib/core/theme, lib/core/widgets      the Ink design system
lib/features/                         feed, article, discover, search, notifications, profile, pro, onboarding
lib/services/providers.dart           Riverpod graph; feed pagination, saved ids, feed meta
lib/services/pro.dart                 RevenueCat integration
```

## Status and honest gaps

Working: collection, ranking, clustering, summaries, images, the full app on Android and web, local persistence, RevenueCat paywall against the Test Store, hourly cron, push job.

Not yet: sync of saved stories to the account, topic-alert filtering on the server, iOS build, store listing. Planning docs: [WORK_TO_BE_DONE.md](WORK_TO_BE_DONE.md), [WORK_DONE.md](WORK_DONE.md).

## Legal

[Privacy](PRIVACY.md) · [Terms](TERMS.md)
