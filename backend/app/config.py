"""
OHeas backend configuration.

Reads from environment / .env file.
Production secrets MUST be injected via environment variables, not .env.
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
    apple_client_id: str = "com.oheas.app"

    # ── OpenAI (for embeddings) ───────────────────────────────
    openai_api_key: str = ""

    # ── LLM Proxy (server-side API key for iOS clients) ───────
    llm_api_key: str = ""
    llm_base_url: str = "https://api.deepseek.com/v1/chat/completions"
    llm_model: str = "deepseek-chat"

    # ── App ───────────────────────────────────────────────────
    debug: bool = False
    cors_origins: str = "http://localhost:8000"

    # ── Rate Limiting ─────────────────────────────────────────
    rate_limit_auth_per_minute: int = 5
    rate_limit_llm_per_minute: int = 20
    rate_limit_general_per_minute: int = 60

    # ── Logging ───────────────────────────────────────────────
    log_level: str = "INFO"
    log_format: str = "json"  # "json" or "console"


settings = Settings()
