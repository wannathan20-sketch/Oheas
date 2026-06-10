"""
OHeas backend configuration.

Reads from environment / .env file.
"""

from __future__ import annotations

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    # ── Database ──────────────────────────────────────────────
    database_url: str = "postgresql+asyncpg://oheas:oheas@localhost:5432/oheas"

    # ── JWT ───────────────────────────────────────────────────
    jwt_secret: str = "change-me-in-production-openssl-rand-hex-32"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    refresh_token_expire_days: int = 30

    # ── Apple Sign In ─────────────────────────────────────────
    apple_team_id: str = ""
    apple_client_id: str = "com.oheas.mvp"

    # ── App ───────────────────────────────────────────────────
    debug: bool = False
    cors_origins: str = "*"


settings = Settings()
