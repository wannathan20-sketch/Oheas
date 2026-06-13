"""
LLM proxy endpoints — chat (SSE streaming) and recommendation (non-streaming).

Both endpoints require JWT authentication. The server-side API key is
never exposed to clients; iOS sends only user messages and the backend
proxies them to the upstream LLM.

When llm_api_key is not configured, endpoints return HTTP 503 so the
iOS client can fall through to local fallback.
"""

from __future__ import annotations

import json
from uuid import UUID

import httpx
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

from app.auth.dependencies import get_current_user_id
from app.config import settings

router = APIRouter(prefix="/v1/llm", tags=["llm"])


# ── Request Models ──────────────────────────────────────────

class ChatMessage(BaseModel):
    role: str = Field(..., description="Message role: system, user, or assistant")
    content: str = Field(..., description="Message content")


class ChatRequest(BaseModel):
    messages: list[ChatMessage] = Field(..., description="Conversation messages")
    temperature: float = Field(0.7, ge=0.0, le=2.0, description="Sampling temperature")
    model: str | None = Field(None, description="Model override")
    max_tokens: int | None = Field(None, ge=1)
    top_p: float | None = Field(None, ge=0.0, le=1.0)
    frequency_penalty: float | None = Field(None, ge=-2.0, le=2.0)
    presence_penalty: float | None = Field(None, ge=-2.0, le=2.0)


class RecommendationRequest(BaseModel):
    system_prompt: str = Field(..., description="System prompt for the coach")
    user_context_json: str = Field(..., description="User health context as JSON string")
    model: str | None = Field(None, description="Model override")


def _check_upstream_ready() -> None:
    """Raise 503 if the upstream LLM is not configured on the server."""
    if not settings.llm_api_key:
        raise HTTPException(
            status_code=503,
            detail="LLM service not configured on server",
        )


@router.post("/chat")
async def llm_chat(
    body: ChatRequest,
    user_id: UUID = Depends(get_current_user_id),
) -> StreamingResponse:
    """
    Proxy multi-turn chat messages to the upstream LLM and stream the
    response back as SSE (Server-Sent Events).

    Response: SSE stream (text/event-stream).
    Each line is an upstream SSE event passed through verbatim,
    terminated by "data: [DONE]".
    """
    _check_upstream_ready()

    upstream_payload: dict = {
        "model": body.model or settings.llm_model,
        "messages": [m.model_dump() for m in body.messages],
        "stream": True,
        "temperature": body.temperature,
    }

    # Forward optional parameters if present
    for key in ("max_tokens", "top_p", "frequency_penalty", "presence_penalty"):
        val = getattr(body, key, None)
        if val is not None:
            upstream_payload[key] = val

    async def _stream():
        async with httpx.AsyncClient(
            timeout=httpx.Timeout(60.0, connect=10.0),
        ) as client:
            async with client.stream(
                "POST",
                settings.llm_base_url,
                json=upstream_payload,
                headers={
                    "Authorization": f"Bearer {settings.llm_api_key}",
                    "Content-Type": "application/json",
                },
            ) as resp:
                if resp.status_code != 200:
                    import logging
                    error_body = await resp.aread()
                    logging.getLogger("oheas").warning(
                        "llm_upstream_error",
                        status=resp.status_code,
                        detail=error_body.decode(errors="replace")[:200],
                    )
                    yield f"data: {json.dumps({'error': 'Upstream LLM error'})}\n\n"
                    yield "data: [DONE]\n\n"
                    return

                async for line in resp.aiter_lines():
                    if line:
                        # Pass through upstream SSE lines verbatim.
                        # The iOS client already knows how to parse
                        # the Chat Completions SSE format.
                        yield f"{line}\n\n"

    return StreamingResponse(
        _stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@router.post("/recommendation")
async def llm_recommendation(
    body: RecommendationRequest,
    user_id: UUID = Depends(get_current_user_id),
) -> dict:
    """
    Generate a structured coach recommendation via the upstream LLM.

    Non-streaming — the backend calls the upstream LLM with JSON mode
    and returns the parsed content.

    Response (JSON):
        {
            "content": "<raw LLM response JSON string>",
            "model": "deepseek-chat"
        }
    """
    _check_upstream_ready()

    messages = [
        {"role": "system", "content": body.system_prompt},
        {"role": "user", "content": body.user_context_json},
    ]

    upstream_payload: dict = {
        "model": body.model or settings.llm_model,
        "messages": messages,
        "stream": False,
        "response_format": {"type": "json_object"},
    }

    async with httpx.AsyncClient(
        timeout=httpx.Timeout(60.0, connect=10.0),
    ) as client:
        resp = await client.post(
            settings.llm_base_url,
            json=upstream_payload,
            headers={
                "Authorization": f"Bearer {settings.llm_api_key}",
                "Content-Type": "application/json",
            },
        )

    if resp.status_code != 200:
        import logging
        logging.getLogger("oheas").warning(
            "llm_upstream_error",
            status=resp.status_code,
            detail=resp.text[:200],
        )
        raise HTTPException(
            status_code=502,
            detail="Upstream LLM error",
        )

    upstream_data = resp.json()
    content = ""
    if "choices" in upstream_data:
        content = (
            upstream_data["choices"][0]
            .get("message", {})
            .get("content", "")
        )

    if not content:
        raise HTTPException(
            status_code=502,
            detail="Upstream LLM returned empty response",
        )

    return {"content": content, "model": upstream_payload["model"]}
