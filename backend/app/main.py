"""OHeas Backend — FastAPI application."""

from __future__ import annotations

import logging
import time
import uuid
from collections import defaultdict
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings

# ── Structured Logging ────────────────────────────────────────


class _StructuredLogger(logging.Logger):
    """Logger subclass that forwards extra kwargs into ``extra`` dict.

    Standard library logging in Python 3.13+ rejects unexpected kwargs
    in ``_log()``. This adapter restores structlog-style calls like
    ``logger.info("msg", key1=val1, key2=val2)`` by forwarding them as
    ``logger.info("msg", extra={"key1": val1, "key2": val2})``.
    """

    def _log(self, level, msg, args, exc_info=None, extra=None, stack_info=False, stacklevel=1, **kwargs):
        if extra is None:
            extra = {}
        extra.update(kwargs)
        super()._log(level, msg, args, exc_info, extra, stack_info, stacklevel)


# Register before any getLogger call so "oheas" picks up the subclass.
_prev_class = logging.getLoggerClass()
logging.setLoggerClass(_StructuredLogger)

logger = logging.getLogger("oheas")

# Restore default class so third-party loggers are unaffected.
logging.setLoggerClass(_prev_class)


def setup_logging() -> None:
    """Configure structured logging (JSON in production, console in dev)."""
    handler: logging.Handler
    if settings.log_format == "json":
        try:
            from pythonjsonlogger import jsonlogger
            handler = logging.StreamHandler()
            formatter = jsonlogger.JsonFormatter(
                "%(asctime)s %(name)s %(levelname)s %(message)s",
                datefmt="%Y-%m-%dT%H:%M:%S",
            )
            handler.setFormatter(formatter)  # type: ignore[arg-type]
        except ImportError:
            handler = logging.StreamHandler()
            handler.setFormatter(
                logging.Formatter(
                    "%(asctime)s [%(levelname)s] %(name)s: %(message)s",
                    datefmt="%Y-%m-%dT%H:%M:%S",
                )
            )
    else:
        handler = logging.StreamHandler()
        handler.setFormatter(
            logging.Formatter(
                "%(asctime)s [%(levelname)s] %(name)s: %(message)s",
                datefmt="%Y-%m-%dT%H:%M:%S",
            )
        )

    root = logging.getLogger("oheas")
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(getattr(logging, settings.log_level.upper(), logging.INFO))

    # Silence noisy third-party loggers in production
    if not settings.debug:
        logging.getLogger("httpx").setLevel(logging.WARNING)
        logging.getLogger("httpcore").setLevel(logging.WARNING)
        logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)


setup_logging()

# ── In-Memory Rate Limiter ────────────────────────────────────

class RateLimiter:
    """Simple in-memory sliding-window rate limiter.

    For production with multiple workers, replace with Redis-backed limiter.
    """

    def __init__(self) -> None:
        self._windows: dict[str, list[float]] = defaultdict(list)
        self._cleanup_at = time.monotonic()

    def _cleanup(self, now: float) -> None:
        if now - self._cleanup_at < 60:
            return
        cutoff = now - 120
        stale = [k for k, v in self._windows.items() if not v or v[-1] < cutoff]
        for k in stale:
            del self._windows[k]
        self._cleanup_at = now

    def is_allowed(self, key: str, max_requests: int, window_seconds: int = 60) -> bool:
        now = time.monotonic()
        self._cleanup(now)
        window = self._windows[key]
        cutoff = now - window_seconds
        # Remove expired entries
        while window and window[0] < cutoff:
            window.pop(0)
        if len(window) >= max_requests:
            return False
        window.append(now)
        return True


rate_limiter = RateLimiter()


def get_rate_limit_key(request: Request) -> tuple[str, int]:
    """Determine rate limit key and max requests per minute for a route."""
    path = request.url.path
    if path.startswith("/v1/auth"):
        return f"auth:{request.client.host if request.client else 'unknown'}", settings.rate_limit_auth_per_minute
    if path.startswith("/v1/llm"):
        return f"llm:{request.client.host if request.client else 'unknown'}", settings.rate_limit_llm_per_minute
    return f"general:{request.client.host if request.client else 'unknown'}", settings.rate_limit_general_per_minute

# ── Lifespan ──────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):  # type: ignore[arg-type]
    """Startup / shutdown hooks."""
    logger.info("OHeas backend starting", version="0.2.0", debug=settings.debug)

    # Pre-flight DB check
    try:
        from app.database import async_session_factory
        async with async_session_factory() as session:
            await session.execute(  # type: ignore[arg-type]
                __import__("sqlalchemy").text("SELECT 1")
            )
        logger.info("Database connection verified")
    except Exception as exc:
        logger.error("Database connection failed on startup", error=str(exc))

    yield

    # Graceful shutdown
    logger.info("OHeas backend shutting down")
    try:
        from app.database import engine
        await engine.dispose()
        logger.info("Database engine disposed")
    except Exception:
        pass


# ── App ────────────────────────────────────────────────────────

app = FastAPI(
    title="OHeas Backend",
    version="0.2.0",
    lifespan=lifespan,
)

# ── Request ID Middleware ──────────────────────────────────────


@app.middleware("http")
async def add_request_id(request: Request, call_next):
    """Attach a unique request ID to every request for tracing."""
    request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
    request.state.request_id = request_id
    start = time.monotonic()

    response = await call_next(request)

    elapsed_ms = (time.monotonic() - start) * 1000
    response.headers["X-Request-ID"] = request_id

    logger.info(
        "request",
        request_id=request_id,
        method=request.method,
        path=request.url.path,
        status=response.status_code,
        elapsed_ms=round(elapsed_ms, 1),
    )
    return response


@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    """Apply rate limiting to all requests."""
    key, max_req = get_rate_limit_key(request)
    if not rate_limiter.is_allowed(key, max_req):
        logger.warning(
            "rate_limit_exceeded",
            key=key,
            path=request.url.path,
            request_id=getattr(request.state, "request_id", "unknown"),
        )
        return JSONResponse(
            status_code=429,
            content={"detail": "Too many requests. Please try again later."},
        )
    return await call_next(request)

# ── CORS ──────────────────────────────────────────────────────

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins.split(","),
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
)

# ── Global Error Handler ──────────────────────────────────────


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catch unhandled exceptions. In production, return generic errors only."""
    import traceback

    request_id = getattr(request.state, "request_id", "unknown")

    logger.error(
        "unhandled_exception",
        request_id=request_id,
        path=request.url.path,
        error_type=type(exc).__name__,
        error=str(exc),
        traceback=traceback.format_exc() if settings.debug else "",
    )

    if settings.debug:
        return JSONResponse(
            status_code=500,
            content={
                "detail": f"{type(exc).__name__}: {exc}",
                "request_id": request_id,
            },
        )
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error",
            "request_id": request_id,
        },
    )

# ── Routers ───────────────────────────────────────────────────

from app.routes import auth, health, llm, sync
from app.rag.routes import router as rag_router

app.include_router(health.router)
app.include_router(auth.router)
app.include_router(sync.router)
app.include_router(rag_router)
app.include_router(llm.router)
