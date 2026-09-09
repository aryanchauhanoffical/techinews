"""Default source list. Everything here is a keyless, structured feed.

Each entry: (source_id, display_name, feed_url, SourceType, weight)
`weight` (0.5–1.5) nudges the relevance score — lab blogs and primary
sources rank above aggregators.
"""
from __future__ import annotations

from app.schemas.article import SourceType

# fmt: off
DEFAULT_FEEDS = [
    # --- AI labs / primary sources ---
    ("openai_blog",     "OpenAI",            "https://openai.com/news/rss.xml",                          SourceType.blog, 1.3),
    ("deepmind_blog",   "Google DeepMind",   "https://deepmind.google/blog/rss.xml",                     SourceType.blog, 1.3),
    ("google_ai_blog",  "Google AI",         "https://blog.google/technology/ai/rss/",                   SourceType.blog, 1.2),
    ("nvidia_blog",     "NVIDIA",            "https://blogs.nvidia.com/feed/",                           SourceType.blog, 1.1),
    ("hf_blog",         "Hugging Face Blog", "https://huggingface.co/blog/feed.xml",                     SourceType.blog, 1.3),
    ("mistral_blog",    "Mistral AI",        "https://mistral.ai/news/rss",                              SourceType.blog, 1.2),
    # --- tech press ---
    ("techcrunch_ai",   "TechCrunch",        "https://techcrunch.com/category/artificial-intelligence/feed/", SourceType.news, 1.0),
    ("techcrunch_su",   "TechCrunch",        "https://techcrunch.com/category/startups/feed/",           SourceType.news, 0.9),
    ("verge_ai",        "The Verge",         "https://www.theverge.com/rss/ai-artificial-intelligence/index.xml", SourceType.news, 0.9),
    ("ars_tech",        "Ars Technica",      "https://feeds.arstechnica.com/arstechnica/technology-lab", SourceType.news, 1.0),
    ("mit_tr",          "MIT Tech Review",   "https://www.technologyreview.com/feed/",                   SourceType.news, 1.0),
    ("venturebeat_ai",  "VentureBeat",       "https://venturebeat.com/category/ai/feed/",                SourceType.news, 0.9),
    ("theinfo_rss",     "Wired",             "https://www.wired.com/feed/tag/ai/latest/rss",             SourceType.news, 0.9),
    # --- newsletters / independent ---
    ("simonw",          "Simon Willison",    "https://simonwillison.net/atom/everything/",               SourceType.blog, 1.2),
    ("latent_space",    "Latent Space",      "https://www.latent.space/feed",                            SourceType.blog, 1.1),
    ("import_ai",       "Import AI",         "https://importai.substack.com/feed",                       SourceType.blog, 1.1),
    ("interconnects",   "Interconnects",     "https://www.interconnects.ai/feed",                        SourceType.blog, 1.1),
    # --- dev tools / OSS ---
    ("github_blog",     "GitHub Blog",       "https://github.blog/feed/",                                SourceType.blog, 1.0),
    ("vercel_blog",     "Vercel",            "https://vercel.com/atom",                                  SourceType.blog, 0.9),
    ("cloudflare_blog", "Cloudflare",        "https://blog.cloudflare.com/rss/",                         SourceType.blog, 0.9),
    # --- community (keyless RSS) ---
    ("r_ml",            "r/MachineLearning", "https://www.reddit.com/r/MachineLearning/top.rss?t=day",   SourceType.reddit, 0.9),
    ("r_localllama",    "r/LocalLLaMA",      "https://www.reddit.com/r/LocalLLaMA/top.rss?t=day",        SourceType.reddit, 1.0),
    ("r_artificial",    "r/artificial",      "https://www.reddit.com/r/artificial/top.rss?t=day",        SourceType.reddit, 0.7),
    ("r_programming",   "r/programming",     "https://www.reddit.com/r/programming/top.rss?t=day",       SourceType.reddit, 0.7),
    ("producthunt",     "Product Hunt",      "https://www.producthunt.com/feed",                         SourceType.product_hunt, 0.8),
    # Developer communities with less noise than Reddit
    ("lobsters",        "Lobste.rs",         "https://lobste.rs/rss",                                    SourceType.news, 0.8),
    ("devto",           "dev.to",            "https://dev.to/feed",                                      SourceType.blog, 0.6),
    # Daily AI digests: good at catching what the labs bury
    ("tldr_ai",         "TLDR AI",           "https://tldr.tech/api/rss/ai",                             SourceType.news, 0.8),
    # Changelogs developers actually read
    ("claude_code_rel", "Claude Code releases", "https://github.com/anthropics/claude-code/releases.atom", SourceType.github, 1.0),
]

# YouTube channels. Keyless: every channel exposes an Atom feed; the video
# thumbnail becomes the story image. (name, channel id), all verified live.
YOUTUBE_CHANNELS = [
    ("AI Explained",      "UCNJ1Ymd5yFuUPtn21xtRbbw"),
    ("Two Minute Papers", "UCbfYPyITQ-7l4upoX8nvctg"),
    ("Fireship",          "UCsBjURrPoezykLs9EqgamOA"),
    ("Theo",              "UCbRP3c757lWg9M-U7TyEkXA"),
    ("Matthew Berman",    "UCawZsQWqfGSbCI5yjkdVkTA"),
    ("Yannic Kilcher",    "UCZHmQk67mSJgfCCTn7xBfew"),
    ("Andrej Karpathy",   "UCXUPKJO5MZQN11PqgIvyuvQ"),
    ("Latent Space",      "UCxBcwypKK-W3GHd_RZ9FZrQ"),
    ("Lex Fridman",       "UCSHZKyawb77ixDdsGog4iWA"),
    ("Dwarkesh Patel",    "UCXl4i9dYBrFOabk0xGmbkRA"),
    ("ThePrimeagen",      "UC8ENHE5xdFSwx71u3fDH5Xw"),
    ("Sam Witteveen",     "UC55ODQSvARtgSyc8ThfiepQ"),
]

# Bluesky accounts. Public API, no auth. Posts that carry an external link
# become stories about that link. (display name, handle), all verified live.
BLUESKY_ACCOUNTS = [
    ("Simon Willison",   "simonwillison.net"),
    ("Andrej Karpathy",  "karpathy.bsky.social"),
    ("Yann LeCun",       "yann-lecun.bsky.social"),
    ("Jeremy Howard",    "howard.fm"),
    ("Emily Bender",     "emilymbender.bsky.social"),
    ("Chris Olah",       "colah.bsky.social"),
    ("Nathan Lambert",   "natolambert.bsky.social"),
    ("Sebastian Raschka","rasbt.bsky.social"),
    ("swyx",             "swyx.io"),
    ("Ethan Mollick",    "emollick.bsky.social"),
    ("Thomas Wolf",      "thomwolf.bsky.social"),
    ("Clem Delangue",    "clem.hf.co"),
    ("hardmaru",         "hardmaru.bsky.social"),
]
# fmt: on

# Repos whose GitHub *releases* are news in themselves (Atom feeds, keyless).
RELEASE_REPOS = [
    "ollama/ollama", "ggml-org/llama.cpp", "vllm-project/vllm", "huggingface/transformers",
    "langchain-ai/langchain", "pytorch/pytorch", "openai/openai-python", "anthropics/anthropic-sdk-python",
    "microsoft/vscode", "flutter/flutter", "vercel/next.js", "denoland/deno",
]

# Vocabulary used by the heuristic ranker (lower-case).
HOT_TERMS = {
    "gpt", "claude", "gemini", "llama", "mistral", "deepseek", "qwen", "openai", "anthropic",
    "deepmind", "nvidia", "agent", "agents", "agentic", "mcp", "llm", "model", "open source",
    "open-source", "release", "launch", "launches", "benchmark", "funding", "raises", "series",
    "acquires", "acquisition", "cuda", "gpu", "inference", "fine-tun", "rag", "vision", "robot",
    "cursor", "copilot", "coding", "rust", "python", "typescript", "kubernetes", "security",
    "breach", "vulnerability", "cve", "apple", "google", "microsoft", "meta", "amazon", "ipo",
}
