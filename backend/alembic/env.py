"""
Alembic env.py — async engine, reads DB URL from app.config, autogenerates from
app.db.models.Base metadata.
"""

import asyncio
from logging.config import fileConfig

from alembic import context
from sqlalchemy import pool
from sqlalchemy.ext.asyncio import create_async_engine

# ── Alembic Config ────────────────────────────────────────────────
config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# ── Metadata for autogenerate ─────────────────────────────────────
from app.db.models import Base  # noqa: E402
target_metadata = Base.metadata

# ── DB URL from our shared config ─────────────────────────────────
from app.config import settings  # noqa: E402

# Alembic expects a sync URL for offline mode; derive from the async one.
ASYNC_URL = settings.database_url
SYNC_URL = ASYNC_URL.replace("+asyncpg", "").replace(
    "postgresql://", "postgresql+psycopg2://"
)


def run_migrations_offline() -> None:
    """Offline mode — emit SQL without connecting to the database."""
    context.configure(
        url=SYNC_URL,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection):
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


async def run_migrations_online() -> None:
    """Online mode — connect to the live database and migrate."""
    connectable = create_async_engine(ASYNC_URL, poolclass=pool.NullPool)

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    asyncio.run(run_migrations_online())
