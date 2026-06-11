"""
Embedding service using OpenAI text-embedding-3-small.

Supports:
- Single text → embedding (1536-d)
- Batch embedding with rate-limit awareness
"""

from __future__ import annotations

import asyncio
import hashlib

from openai import AsyncOpenAI

from app.config import settings

# Reuse the OPENAI_API_KEY if set, otherwise embedding is disabled.
_client: AsyncOpenAI | None = None


def _get_client() -> AsyncOpenAI | None:
    global _client
    if _client is None:
        key = getattr(settings, "openai_api_key", None) or None
        if not key:
            return None
        _client = AsyncOpenAI(api_key=key)
    return _client


EMBEDDING_MODEL = "text-embedding-3-small"
EMBEDDING_DIMS = 1536


async def embed_text(text: str) -> list[float] | None:
    """Generate a single embedding. Returns None if OpenAI is not configured."""
    client = _get_client()
    if client is None:
        return None

    # Truncate to ~8000 tokens to stay well under the 8192 limit
    truncated = text[:32000]

    resp = await client.embeddings.create(
        model=EMBEDDING_MODEL,
        input=truncated,
        dimensions=EMBEDDING_DIMS,
    )
    return resp.data[0].embedding


async def embed_batch(texts: list[str], concurrency: int = 5) -> list[list[float] | None]:
    """Generate embeddings for a batch of texts with concurrency control."""
    sem = asyncio.Semaphore(concurrency)

    async def _one(text: str) -> list[float] | None:
        async with sem:
            return await embed_text(text)

    return await asyncio.gather(*[_one(t) for t in texts])


def content_hash(content: str) -> str:
    """Deterministic hash for dedup — skip re-embedding if content unchanged."""
    return hashlib.sha256(content.encode()).hexdigest()[:16]
