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
    nickname: str | None = None

    @staticmethod
    def from_user(user: "AuthUser", access_token: str, refresh_token: str) -> "TokenResponse":
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user_id=user.id,
            nickname=user.nickname,
        )


class RefreshRequest(BaseModel):
    refresh_token: str


class DeviceLoginRequest(BaseModel):
    device_id: str = Field(..., description="Unique device identifier (UUID)")
    device_name: str | None = Field(None, description="Optional device name for display")


class EmailLoginRequest(BaseModel):
    email: str = Field(..., description="User email address")
    password: str = Field(..., min_length=8, description="User password (min 8 chars)")


class EmailRegisterRequest(BaseModel):
    email: str = Field(..., description="User email address")
    password: str = Field(..., min_length=8, description="User password (min 8 chars)")
    nickname: str | None = Field(None, max_length=64, description="Optional display nickname")


class EmailBindRequest(BaseModel):
    email: str = Field(..., description="Email to bind to the current account")
    password: str = Field(..., min_length=8, description="Password for email login (min 8 chars)")


class SetNicknameRequest(BaseModel):
    nickname: str = Field(..., min_length=1, max_length=64, description="Display nickname")


# ── Device Anonymous Login ────────────────────────────────────


@router.post("/device", response_model=TokenResponse)
async def device_login(
    request: DeviceLoginRequest,
    repo: AuthRepository = Depends(_get_repo),
) -> TokenResponse:
    """Anonymous login via device ID. No Apple account required.

    On first call with a new device_id, a user account is created.
    On subsequent calls, the existing user is returned.
    The device_id should be a stable UUID stored in the iOS Keychain.
    """
    user = await repo.find_by_device_id(request.device_id)
    if user is None:
        user = await repo.create_device_user(request.device_id)
    else:
        await repo.update_last_login(user.id)

    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    return TokenResponse.from_user(user, access_token, refresh_token)


# ── Email Login ─────────────────────────────────────────────


@router.post("/email", response_model=TokenResponse)
async def email_login(
    request: EmailLoginRequest,
    repo: AuthRepository = Depends(_get_repo),
) -> TokenResponse:
    """Login with email + password.

    Returns JWT pair on success, 401 on bad credentials.
    Use this to recover an account on a new device after binding email.
    """
    import bcrypt

    user = await repo.find_by_email(request.email)
    if user is None:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if user.password_hash is None:
        # Don't reveal whether the account exists or has no password.
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if not bcrypt.checkpw(
        request.password.encode("utf-8"),
        user.password_hash.encode("utf-8"),
    ):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    await repo.update_last_login(user.id)

    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    return TokenResponse.from_user(user, access_token, refresh_token)


# ── Email Registration ─────────────────────────────────────────


@router.post("/register", response_model=TokenResponse)
async def email_register(
    request: EmailRegisterRequest,
    repo: AuthRepository = Depends(_get_repo),
) -> TokenResponse:
    """Register a new account with email + password.

    Creates a new user with bcrypt-hashed password.
    Returns JWT pair on success, 409 if the email is already registered.
    """
    import bcrypt

    # Check if email already exists.
    existing = await repo.find_by_email(request.email)
    if existing is not None:
        raise HTTPException(status_code=409, detail="Email already registered")

    password_hash = bcrypt.hashpw(
        request.password.encode("utf-8"),
        bcrypt.gensalt(),
    ).decode("utf-8")

    user = await repo.create_user_with_email_password(
        request.email, password_hash, request.nickname
    )

    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    return TokenResponse.from_user(user, access_token, refresh_token)


@router.post("/bind-email")
async def bind_email(
    request: EmailBindRequest,
    user_id: UUID = Depends(get_current_user_id),
    repo: AuthRepository = Depends(_get_repo),
) -> dict[str, str]:
    """Bind an email + password to the currently authenticated user.

    Allows users who signed up via device anonymous login or Apple Sign In
    to add email-based recovery for cross-device account access.
    Returns 409 if the email is already in use by a different user.
    """
    import bcrypt

    # Check if email is already taken by another user.
    existing = await repo.find_by_email(request.email)
    if existing is not None and existing.id != user_id:
        raise HTTPException(status_code=409, detail="Email already in use by another account")

    password_hash = bcrypt.hashpw(
        request.password.encode("utf-8"),
        bcrypt.gensalt(),
    ).decode("utf-8")

    updated = await repo.update_user_email_password(user_id, request.email, password_hash)
    if updated is None:
        raise HTTPException(status_code=404, detail="User not found")

    return {"status": "ok", "email": request.email}


@router.post("/set-nickname")
async def set_nickname(
    request: SetNicknameRequest,
    user_id: UUID = Depends(get_current_user_id),
    repo: AuthRepository = Depends(_get_repo),
) -> dict[str, str]:
    """Set or change the display nickname for the authenticated user.

    Returns 409 if the nickname is already taken by another user.
    """
    nickname = request.nickname.strip()

    # Check uniqueness — nickname is globally unique for display purposes.
    existing = await repo.find_by_nickname(nickname)
    if existing is not None and existing.id != user_id:
        raise HTTPException(
            status_code=409,
            detail="Nickname already taken. Please choose another.",
        )

    updated = await repo.update_nickname(user_id, nickname)
    if updated is None:
        raise HTTPException(status_code=404, detail="User not found")

    return {"status": "ok", "nickname": nickname}


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

    return TokenResponse.from_user(user, access_token, refresh_token)


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
        nickname=user.nickname,
    )


# ── Sign out ──────────────────────────────────────────────────


@router.delete("/session")
async def sign_out(
    user_id: UUID = Depends(get_current_user_id),
) -> dict[str, str]:
    # Stateless JWT — the client is responsible for discarding tokens.
    # In a future version we could maintain a token blocklist.
    return {"status": "logged_out", "user_id": str(user_id)}


# ── GDPR Account Deletion ───────────────────────────────────


@router.delete("/account")
async def delete_account(
    user_id: UUID = Depends(get_current_user_id),
    repo: AuthRepository = Depends(_get_repo),
) -> dict[str, str]:
    """Permanently delete the authenticated user's account and all data.

    Implements GDPR Article 17 (Right to erasure).
    Deletes the user row and all associated sync records from the database.
    The client MUST discard all local tokens after this call.
    """
    deleted = await repo.delete_user(user_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="User not found")
    return {"status": "deleted", "user_id": str(user_id)}
