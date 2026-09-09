# Asset credits

Every external asset shipped in the app, per the TechiNews asset rules.

| Asset | Source | URL | License | Attribution required | Notes |
|---|---|---|---|---|---|
| `assets/illustrations/doodle-*.svg` (9 figures) | Open Doodles by Pablo Stanley | https://www.opendoodles.com/ | CC0 1.0 | No | Extracted from the MIT `react-open-doodles` npm package; accent recoloured at load to TechiNews hues. Not redistributed as a pack. |
| `assets/images/illustration-splash-hero.png` | Made by the TechiNews team (AI-assisted) | n/a | Project-owned | No | Transparent poster illustration for the splash. |
| `assets/fallbacks/fallback-*.jpg` (11 category images) | Generated for TechiNews with Cloudflare Workers AI (FLUX.1 schnell) using the asset-rules base prompt | n/a | Project-owned | No | Shown when a story has no image; picked by first topic. 800px JPEG. |
| Phosphor Icons (via `phosphor_flutter`) | Phosphor | https://phosphoricons.com/ | MIT | No | Single icon family for all UI controls. |
| Brand marks (loaded at runtime) | Simple Icons | https://simpleicons.org/ | CC0 1.0 (icons); brand marks remain their owners' trademarks | No | Loaded from cdn.simpleicons.org for recognised sources only; rendered in white, never restyled. |
| Fonts: Shantell Sans, DM Sans, Kalam | Google Fonts | https://fonts.google.com/ | OFL 1.1 | No | Loaded via `google_fonts`. |
| Painted doodles (sparks, scribbles, arrows, stickers) | TechiNews `lib/core/widgets/doodles.dart` | n/a | Project-owned | No | CustomPainter, no external files. |
