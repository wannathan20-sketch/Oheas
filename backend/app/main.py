"""OHeas Backend — FastAPI application."""

from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routes import auth, health, sync
from app.rag.routes import router as rag_router


@asynccontextmanager
async def lifespan(app: FastAPI):  # type: ignore[arg-type]
    """Startup / shutdown hooks."""
    # Nothing to init yet — DB is lazy.
    yield


app = FastAPI(
    title="OHeas Backend",
    version="0.2.0",
    lifespan=lifespan,
)

# ── CORS ──────────────────────────────────────────────────────

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins.split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────

app.include_router(health.router)
app.include_router(auth.router)
app.include_router(sync.router)
app.include_router(rag_router)
