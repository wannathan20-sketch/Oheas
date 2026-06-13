"""
Repository layer — enforces user_id ownership on every operation.

Every public method requires an explicit `user_id: UUID` argument.
This replaces DB-level RLS (which requires Supabase Auth's `auth.uid()`).
"""

from __future__ import annotations

from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select

from app.database import async_session_factory
from app.db.models import AuthUser, SyncRecordModel
from app.models import SyncEnvelope


class AuthRepository:
    """User account operations."""

    async def find_by_apple_id(self, apple_user_id: str) -> AuthUser | None:
        async with async_session_factory() as session:
            result = await session.execute(
                select(AuthUser).where(AuthUser.apple_user_id == apple_user_id)
            )
            return result.scalar_one_or_none()

    async def find_by_id(self, user_id: UUID) -> AuthUser | None:
        async with async_session_factory() as session:
            result = await session.execute(
                select(AuthUser).where(AuthUser.id == user_id)
            )
            return result.scalar_one_or_none()

    async def find_by_device_id(self, device_id: str) -> AuthUser | None:
        async with async_session_factory() as session:
            result = await session.execute(
                select(AuthUser).where(AuthUser.device_id == device_id)
            )
            return result.scalar_one_or_none()

    async def find_by_email(self, email: str) -> AuthUser | None:
        async with async_session_factory() as session:
            result = await session.execute(
                select(AuthUser).where(AuthUser.email == email)
            )
            return result.scalar_one_or_none()

    async def find_by_nickname(self, nickname: str) -> AuthUser | None:
        async with async_session_factory() as session:
            result = await session.execute(
                select(AuthUser).where(AuthUser.nickname == nickname)
            )
            return result.scalar_one_or_none()

    async def create_user(self, apple_user_id: str, full_name: str | None = None) -> AuthUser:
        user = AuthUser(apple_user_id=apple_user_id, full_name=full_name)
        async with async_session_factory() as session:
            session.add(user)
            await session.commit()
            await session.refresh(user)
        return user

    async def create_device_user(self, device_id: str) -> AuthUser:
        """Create a new user identified only by device ID (anonymous login)."""
        user = AuthUser(device_id=device_id)
        async with async_session_factory() as session:
            session.add(user)
            await session.commit()
            await session.refresh(user)
        return user

    async def update_user_email_password(
        self, user_id: UUID, email: str, password_hash: str
    ) -> AuthUser | None:
        """Set or update email + password for an existing user."""
        async with async_session_factory() as session:
            result = await session.execute(
                select(AuthUser).where(AuthUser.id == user_id)
            )
            user = result.scalar_one_or_none()
            if user is None:
                return None
            user.email = email
            user.password_hash = password_hash
            user.last_login_at = datetime.now(timezone.utc)
            await session.commit()
            await session.refresh(user)
        return user

    async def create_user_with_email_password(
        self, email: str, password_hash: str, nickname: str | None = None
    ) -> AuthUser:
        """Create a new user with email + password (registration)."""
        user = AuthUser(
            email=email,
            password_hash=password_hash,
            nickname=nickname,
        )
        async with async_session_factory() as session:
            session.add(user)
            await session.commit()
            await session.refresh(user)
        return user

    async def update_nickname(self, user_id: UUID, nickname: str) -> AuthUser | None:
        """Set or update the display nickname for a user."""
        async with async_session_factory() as session:
            result = await session.execute(
                select(AuthUser).where(AuthUser.id == user_id)
            )
            user = result.scalar_one_or_none()
            if user is None:
                return None
            user.nickname = nickname
            user.last_login_at = datetime.now(timezone.utc)
            await session.commit()
            await session.refresh(user)
        return user

    async def update_last_login(self, user_id: UUID) -> None:
        async with async_session_factory() as session:
            result = await session.execute(
                select(AuthUser).where(AuthUser.id == user_id)
            )
            user = result.scalar_one_or_none()
            if user is not None:
                user.last_login_at = datetime.now(timezone.utc)
                await session.commit()

    async def delete_user(self, user_id: UUID) -> bool:
        """Permanently delete a user and all associated data (GDPR right to erasure).

        Deletes sync records and the user row in a single transaction.
        Returns True if a user was deleted, False if not found.
        """
        from sqlalchemy import delete

        async with async_session_factory() as session:
            async with session.begin():
                # Delete all sync records for this user.
                await session.execute(
                    delete(SyncRecordModel).where(SyncRecordModel.user_id == user_id)
                )
                # Delete the user.
                result = await session.execute(
                    delete(AuthUser).where(AuthUser.id == user_id)
                )
                deleted = result.rowcount > 0
        return deleted


class SyncRepository:
    """Sync record persistence with ownership enforcement."""

    async def upsert(self, user_id: UUID, record: SyncEnvelope) -> None:
        """Insert or update a sync record. Last-write-wins on updated_at."""
        async with async_session_factory() as session:
            # Check for existing record (same user_id + entity_type + entity_id).
            result = await session.execute(
                select(SyncRecordModel).where(
                    SyncRecordModel.user_id == user_id,
                    SyncRecordModel.entity_type == record.entity_type.value,
                    SyncRecordModel.entity_id == record.entity_id,
                )
            )
            existing = result.scalar_one_or_none()

            if existing is not None:
                # Last-write-wins: only overwrite if incoming is newer.
                if record.updated_at >= existing.updated_at:
                    existing.operation = record.operation.value
                    existing.payload = record.payload
                    existing.updated_at = record.updated_at
                    existing.deleted_at = record.deleted_at
            else:
                model = SyncRecordModel(
                    id=record.id,
                    user_id=user_id,
                    entity_type=record.entity_type.value,
                    entity_id=record.entity_id,
                    operation=record.operation.value,
                    payload=record.payload,
                    created_at=record.updated_at,
                    updated_at=record.updated_at,
                    deleted_at=record.deleted_at,
                )
                session.add(model)

            await session.commit()

    async def fetch_changes(
        self, user_id: UUID, since: datetime | None = None
    ) -> list[SyncEnvelope]:
        """Return all records for a user, optionally since a timestamp."""
        async with async_session_factory() as session:
            stmt = select(SyncRecordModel).where(
                SyncRecordModel.user_id == user_id
            )
            if since is not None:
                stmt = stmt.where(SyncRecordModel.updated_at > since)
            stmt = stmt.order_by(SyncRecordModel.updated_at.asc())

            result = await session.execute(stmt)
            rows = result.scalars().all()

        return [_model_to_envelope(r) for r in rows]

    async def mark_deleted(
        self, user_id: UUID, entity_type: str, entity_id: str
    ) -> None:
        """Soft-delete by setting deleted_at."""
        async with async_session_factory() as session:
            result = await session.execute(
                select(SyncRecordModel).where(
                    SyncRecordModel.user_id == user_id,
                    SyncRecordModel.entity_type == entity_type,
                    SyncRecordModel.entity_id == entity_id,
                )
            )
            existing = result.scalar_one_or_none()

            if existing is not None:
                now = datetime.now(timezone.utc)
                existing.deleted_at = now
                existing.updated_at = now
                existing.operation = "delete"
            else:
                # Record doesn't exist yet — create a tombstone.
                from app.models import EntityType, SyncOperation
                model = SyncRecordModel(
                    user_id=user_id,
                    entity_type=entity_type,
                    entity_id=entity_id,
                    operation="delete",
                    payload={},
                    deleted_at=datetime.now(timezone.utc),
                )
                session.add(model)

            await session.commit()


def _model_to_envelope(m: SyncRecordModel) -> SyncEnvelope:
    from app.models import EntityType, SyncOperation

    return SyncEnvelope(
        id=m.id,
        user_id=m.user_id,
        entity_type=EntityType(m.entity_type),
        entity_id=m.entity_id,
        operation=SyncOperation(m.operation),
        payload=m.payload,
        updated_at=m.updated_at,
        deleted_at=m.deleted_at,
    )
