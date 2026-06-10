"""
FastAPI dependencies for authentication.

Inject `current_user_id` into any route by adding:
    user_id: UUID = Depends(get_current_user_id)
"""

from __future__ import annotations

from uuid import UUID

from fastapi import Header, HTTPException

from app.auth.jwt import decode_token


async def get_current_user_id(
    authorization: str = Header(..., description="Bearer <access_token>"),
) -> UUID:
    """Validate the access token and return the authenticated user_id."""
    token = authorization.removeprefix("Bearer ").strip()

    if not token:
        raise HTTPException(status_code=401, detail="Missing bearer token")

    try:
        payload = decode_token(token)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired access token")

    if payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="Token is not an access token")

    sub = payload.get("sub")
    if not sub:
        raise HTTPException(status_code=401, detail="Missing subject in token")

    try:
        return UUID(sub)
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid user ID in token")
