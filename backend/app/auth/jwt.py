"""
JWT encode / decode for our own access and refresh tokens.

Uses HS256 symmetric signing. In production, consider RS256 with a key pair.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

import jwt as pyjwt

from app.config import settings


def create_access_token(user_id: str, expires_minutes: int | None = None) -> str:
    """Issue a short-lived access token."""
    if expires_minutes is None:
        expires_minutes = settings.access_token_expire_minutes

    now = datetime.now(timezone.utc)
    payload = {
        "sub": user_id,
        "type": "access",
        "iat": now,
        "exp": now + timedelta(minutes=expires_minutes),
    }
    return pyjwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_refresh_token(user_id: str, expires_days: int | None = None) -> str:
    """Issue a long-lived refresh token."""
    if expires_days is None:
        expires_days = settings.refresh_token_expire_days

    now = datetime.now(timezone.utc)
    payload = {
        "sub": user_id,
        "type": "refresh",
        "iat": now,
        "exp": now + timedelta(days=expires_days),
    }
    return pyjwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_token(token: str) -> dict:
    """Decode and validate a JWT. Raises on expiry / invalid signature."""
    return pyjwt.decode(
        token,
        settings.jwt_secret,
        algorithms=[settings.jwt_algorithm],
        options={"require": ["sub", "type", "exp"]},
    )
