"""RAG endpoints — semantic search + memory indexing."""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth.dependencies import get_current_user_id
from app.database import get_session
from app.rag.embedding_service import EMBEDDING_DIMS, content_hash, embed_batch, embed_text

router = APIRouter(prefix="/v1/rag", tags=["rag"])


# ── Request / Response models ──────────────────────────────────


class RAGSearchRequest(BaseModel):
    query: str = Field(..., min_length=1, max_length=2000)
    top_k: int = Field(default=3, ge=1, le=10)
    source_types: list[str] | None = Field(
        default=None,
        description="Filter by source type: pattern, intervention, feedback, experiment, recommendation, review",
    )


class RAGSearchResult(BaseModel):
    id: UUID
    source_type: str
    source_id: str
    content: str
    similarity: float


class RAGSearchResponse(BaseModel):
    results: list[RAGSearchResult]
    query_embedding_generated: bool


class MemoryIndexRequest(BaseModel):
    items: list[dict] = Field(..., max_length=50)
    # Each item: {"source_type": "...", "source_id": "...", "content": "..."}


class MemoryIndexResponse(BaseModel):
    indexed: int
    skipped: int


# ── Search ─────────────────────────────────────────────────────


@router.post("/search", response_model=RAGSearchResponse)
async def rag_search(
    req: RAGSearchRequest,
    user_id: UUID = Depends(get_current_user_id),
    session: AsyncSession = Depends(get_session),
) -> RAGSearchResponse:
    """Semantic search over user's health memory using pgvector cosine similarity."""
    query_embedding = await embed_text(req.query)

    if query_embedding is None:
        # No embedding available — fall back to text search
        return await _text_fallback_search(session, user_id, req)

    # pgvector cosine similarity search
    # Use ::vector cast + cosine distance operator
    embedding_literal = "[" + ",".join(str(v) for v in query_embedding) + "]"

    source_filter = ""
    params: dict = {"user_id": user_id, "top_k": req.top_k}
    if req.source_types:
        source_filter = "AND source_type = ANY(:source_types)"
        params["source_types"] = req.source_types

    sql = text(
        f"""
        SELECT id, source_type, source_id, content,
               1 - (embedding <=> :embedding::vector({EMBEDDING_DIMS})) AS similarity
        FROM memory_embeddings
        WHERE user_id = :user_id
          AND embedding IS NOT NULL
          {source_filter}
        ORDER BY embedding <=> :embedding::vector({EMBEDDING_DIMS})
        LIMIT :top_k
        """
    )

    result = await session.execute(sql, {**params, "embedding": embedding_literal})
    rows = result.fetchall()

    results = [
        RAGSearchResult(
            id=row.id,
            source_type=row.source_type,
            source_id=row.source_id,
            content=row.content,
            similarity=round(row.similarity, 4),
        )
        for row in rows
    ]

    return RAGSearchResponse(results=results, query_embedding_generated=True)


async def _text_fallback_search(
    session: AsyncSession,
    user_id: UUID,
    req: RAGSearchRequest,
) -> RAGSearchResponse:
    """Fallback: basic ILIKE search when embeddings are unavailable."""
    words = req.query.split()[:10]
    if not words:
        return RAGSearchResponse(results=[], query_embedding_generated=False)

    ilike_clauses = " OR ".join([f"content ILIKE '%' || :w{i} || '%'" for i in range(len(words))])
    params = {f"w{i}": w for i, w in enumerate(words)}
    params["user_id"] = user_id
    params["top_k"] = req.top_k

    sql = text(
        f"""
        SELECT id, source_type, source_id, content, 0.0 AS similarity
        FROM memory_embeddings
        WHERE user_id = :user_id AND ({ilike_clauses})
        LIMIT :top_k
        """
    )
    result = await session.execute(sql, params)
    rows = result.fetchall()

    results = [
        RAGSearchResult(
            id=row.id, source_type=row.source_type,
            source_id=row.source_id, content=row.content, similarity=0.0,
        )
        for row in rows
    ]
    return RAGSearchResponse(results=results, query_embedding_generated=False)


# ── Index memories ─────────────────────────────────────────────


@router.post("/index", response_model=MemoryIndexResponse)
async def index_memories(
    req: MemoryIndexRequest,
    user_id: UUID = Depends(get_current_user_id),
    session: AsyncSession = Depends(get_session),
) -> MemoryIndexResponse:
    """Batch index health memory items: generate embeddings and upsert into pgvector."""
    if not req.items:
        return MemoryIndexResponse(indexed=0, skipped=0)

    # 1. Check which items already have the same content hash (dedup)
    indexed = 0
    skipped = 0

    # 2. Generate embeddings in batch
    contents = [item["content"] for item in req.items]
    embeddings = await embed_batch(contents)

    for item, emb in zip(req.items, embeddings):
        if emb is None:
            skipped += 1
            continue

        source_type = item["source_type"]
        source_id = str(item["source_id"])
        content = item["content"]
        ch = content_hash(content)

        # Check for existing identical content
        check_sql = text(
            """
            SELECT id FROM memory_embeddings
            WHERE user_id = :user_id AND source_type = :source_type AND source_id = :source_id
        """
        )
        result = await session.execute(
            check_sql,
            {"user_id": user_id, "source_type": source_type, "source_id": source_id},
        )
        existing = result.fetchone()

        embedding_literal = "[" + ",".join(str(v) for v in emb) + "]"

        if existing:
            # Update embedding if content changed
            update_sql = text(
                f"""
                UPDATE memory_embeddings
                SET content = :content,
                    embedding = :embedding::vector({EMBEDDING_DIMS})
                WHERE id = :id
                """
            )
            await session.execute(
                update_sql,
                {"content": content, "embedding": embedding_literal, "id": existing.id},
            )
        else:
            insert_sql = text(
                f"""
                INSERT INTO memory_embeddings (user_id, source_type, source_id, content, embedding)
                VALUES (:user_id, :source_type, :source_id, :content, :embedding::vector({EMBEDDING_DIMS}))
                """
            )
            await session.execute(
                insert_sql,
                {
                    "user_id": user_id,
                    "source_type": source_type,
                    "source_id": source_id,
                    "content": content,
                    "embedding": embedding_literal,
                },
            )
        indexed += 1

    await session.commit()
    return MemoryIndexResponse(indexed=indexed, skipped=skipped)
