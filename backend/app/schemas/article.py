from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field


class SourceType(str, Enum):
    news = "news"
    blog = "blog"
    hacker_news = "hacker_news"
    reddit = "reddit"
    product_hunt = "product_hunt"
    github = "github"


class ArticleSource(BaseModel):
    id: str
    name: str
    icon_url: Optional[str] = None
    type: SourceType


class GithubRepo(BaseModel):
    id: str
    full_name: str
    description: str
    url: str
    language: Optional[str] = None
    stars: int = 0
    forks: int = 0
    stars_this_week: int = 0
    readme_excerpt: Optional[str] = None
    last_commit: Optional[datetime] = None


class SocialPlatform(str, Enum):
    reddit = "reddit"
    twitter = "twitter"
    hacker_news = "hacker_news"


class SocialPost(BaseModel):
    id: str
    platform: SocialPlatform
    author: str
    author_handle: Optional[str] = None
    content: str
    url: str
    upvotes: int = 0
    comments: int = 0
    posted_at: datetime
    sentiment: str = "neutral"


class Article(BaseModel):
    id: str
    title: str
    summary: Optional[str] = None
    body: Optional[str] = None
    image_url: Optional[str] = None
    url: str
    source: ArticleSource
    author: Optional[str] = None
    published_at: datetime
    topics: List[str] = Field(default_factory=list)
    companies: List[str] = Field(default_factory=list)
    stack: List[str] = Field(default_factory=list)
    trend_score: int = 0
    virality_score: int = 0
    why_it_matters: Optional[str] = None
    key_points: List[str] = Field(default_factory=list)
    related_repos: List[GithubRepo] = Field(default_factory=list)
    discussions: List[SocialPost] = Field(default_factory=list)


class FeedResponse(BaseModel):
    items: List[Article]
    next_page: Optional[int] = None
