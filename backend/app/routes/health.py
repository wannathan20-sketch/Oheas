"""Health check endpoints — liveness and readiness probes."""

from __future__ import annotations

import httpx
from fastapi import APIRouter
from sqlalchemy import text

from app.config import settings
from app.database import async_session_factory

router = APIRouter(tags=["health"])


@router.get("/health")
async def health() -> dict[str, str]:
    """Liveness probe: lightweight check that the process is alive."""
    return {"status": "ok"}


@router.get("/readyz")
async def readyz() -> dict[str, str | bool]:
    """Readiness probe: verifies DB and upstream LLM connectivity.

    Returns 200 only if all dependencies are reachable.
    Orchestrators (K8s, Zeabur) use this to route traffic.
    """
    checks: dict[str, str | bool] = {"status": "ok"}

    # ── Database ──
    try:
        async with async_session_factory() as session:
            await session.execute(text("SELECT 1"))
        checks["db"] = True
    except Exception as exc:
        checks["status"] = "degraded"
        checks["db"] = False
        checks["db_error"] = str(exc)[:200]

    # ── LLM upstream (only if configured) ──
    if settings.llm_api_key:
        try:
            async with httpx.AsyncClient(timeout=httpx.Timeout(5.0, connect=3.0)) as client:
                resp = await client.get(
                    settings.llm_base_url.rsplit("/", 1)[0] + "/models",
                    headers={"Authorization": f"Bearer {settings.llm_api_key}"},
                )
            checks["llm_upstream"] = resp.status_code < 500
        except Exception as exc:
            checks["status"] = "degraded"
            checks["llm_upstream"] = False
            checks["llm_error"] = str(exc)[:200]

    return checks
