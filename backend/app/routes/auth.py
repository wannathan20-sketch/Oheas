"""Auth endpoints — Apple Sign In + JWT."""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException

from app.auth.apple import verify_apple_identity_token
from app.auth.dependencies import get_current_user_id
from app.auth.jwt import (
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.db.repository import AuthRepository

router = APIRouter(prefix="/v1/auth", tags=["auth"])

_repo: AuthRepository | None = None


def _get_repo() -> AuthRepository:
    global _repo
    if _repo is None:
        _repo = AuthRepository()
    return _repo


# ── Request / Response models ─────────────────────────────────

from pydantic import BaseModel, Field


class AppleSignInRequest(BaseModel):
    identity_token: str = Field(..., description="Apple ID identityToken (JWT)")
    full_name: str | None = Field(None, description="User's display name on first sign-in")


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user_id: UUID


class RefreshRequest(BaseModel):
    refresh_token: str


# ── Apple Sign In ─────────────────────────────────────────────


@router.post("/apple", response_model=TokenResponse)
async def sign_in_with_apple(
    request: AppleSignInRequest,
    repo: AuthRepository = Depends(_get_repo),
) -> TokenResponse:
    # Verify the Apple-issued identity token.
    apple_sub = await verify_apple_identity_token(request.identity_token)

    # Find or create the user.
    user = await repo.find_by_apple_id(apple_sub)
    if user is None:
        user = await repo.create_user(apple_user_id=apple_sub, full_name=request.full_name)
    else:
        await repo.update_last_login(user.id)

    # Issue our own JWT pair.
    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user_id=user.id,
    )


# ── Token refresh ─────────────────────────────────────────────


@router.post("/refresh", response_model=TokenResponse)
async def refresh_access_token(
    request: RefreshRequest,
    repo: AuthRepository = Depends(_get_repo),
) -> TokenResponse:
    try:
        payload = decode_token(request.refresh_token)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    if payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Token is not a refresh token")

    user_id = UUID(payload["sub"])

    # Verify user still exists.
    user = await repo.find_by_id(user_id)
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")

    return TokenResponse(
        access_token=create_access_token(str(user_id)),
        refresh_token=create_refresh_token(str(user_id)),
        user_id=user_id,
    )


# ── Sign out ──────────────────────────────────────────────────


@router.delete("/session")
async def sign_out(
    user_id: UUID = Depends(get_current_user_id),
) -> dict[str, str]:
    # Stateless JWT — the client is responsible for discarding tokens.
    # In a future version we could maintain a token blocklist.
    return {"status": "logged_out", "user_id": str(user_id)}
