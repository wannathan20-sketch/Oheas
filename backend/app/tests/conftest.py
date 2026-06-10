"""Shared test fixtures for OHeas backend."""

from __future__ import annotations

import asyncio
import uuid
from typing import AsyncGenerator

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.db.models import Base
from app.main import app

# In-memory SQLite for tests.
TEST_DATABASE_URL = "sqlite+aiosqlite://"
_test_engine = create_async_engine(TEST_DATABASE_URL, echo=False)
_test_session_factory = async_sessionmaker(_test_engine, class_=AsyncSession, expire_on_commit=False)

# Ensure tables are created once.
_table_lock = asyncio.Lock()
_tables_created = False


async def _ensure_tables() -> None:
    global _tables_created
    async with _table_lock:
        if not _tables_created:
            async with _test_engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            _tables_created = True


@pytest.fixture(autouse=True)
async def _setup_db(monkeypatch: pytest.MonkeyPatch) -> None:
    """Replace production session factory with test SQLite and ensure tables exist."""
    await _ensure_tables()

    import app.database as db_module
    import app.db.repository as repo_module

    monkeypatch.setattr(db_module, "async_session_factory", _test_session_factory)
    monkeypatch.setattr(repo_module, "async_session_factory", _test_session_factory)


@pytest.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


@pytest.fixture
def test_user_id() -> uuid.UUID:
    return uuid.uuid4()
