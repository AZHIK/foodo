"""Store and store-setting endpoints.

Store endpoints are business-scoped: the path ``business_id`` must always
match the token's active business context. Viewing stores only requires that
context — any authenticated member of the business can see its store list,
the same way logging in and landing on the dashboard doesn't ask for a
specific grant. Mutating routes (create/update) still require the relevant
``stores.*`` permission code.

Store settings are one-to-one with their store and are created atomically
with it (both at business creation and standalone store creation), so there
is deliberately NO standalone POST for settings — only GET/PATCH. The
store-level ``stores.update`` code is reused for the settings PATCH route: a
settings row is intrinsic to its store, so a separate STORE_SETTINGS_* code
set would add seed surface without any distinct authorization semantics.
"""

from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.database import get_async_session
from app.core.exceptions import InvalidStoreTypeError
from app.core.permission_codes import PermissionCode
from app.deps.permissions import require_business_context, require_business_permission
from app.models.business import Business, Store, StoreSetting
from app.schemas.store import StoreCreate, StoreRead, StoreUpdate
from app.schemas.store_setting import StoreSettingRead, StoreSettingUpdate
from app.services.store import generate_store_token, validate_store_type

router = APIRouter(prefix="/api/v1/businesses", tags=["Stores"])


async def _get_business_or_404(db: AsyncSession, business_id: UUID) -> Business:
    biz = await db.get(Business, business_id)
    if biz is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
    return biz


async def _get_store_or_404(db: AsyncSession, business_id: UUID, store_id: UUID) -> Store:
    store = await db.get(Store, store_id)
    if store is None or store.business_id != business_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Store not found")
    return store


def _require_context_match(business_id: UUID, caller_business_id: str) -> None:
    if str(business_id) != caller_business_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Token business context does not match the requested business",
        )


def _apply_update(model: object, values: dict[str, Any]) -> None:
    for field, value in values.items():
        setattr(model, field, value)


# ── Stores ───────────────────────────────────────────────────────────────


@router.get("/{business_id}/stores", response_model=list[StoreRead])
async def list_stores(
    business_id: UUID,
    db: AsyncSession = Depends(get_async_session),
    # Viewing your own business's stores is basic post-login navigation, not
    # a privilege some staff can be denied — any authenticated member of the
    # business context may see the list. STORES_VIEW still gates nothing
    # here on purpose; it's checked on the mutation routes below.
    caller_business_id: str = Depends(require_business_context()),
) -> list[Store]:
    _require_context_match(business_id, caller_business_id)

    stores = (
        await db.exec(
            select(Store).where(Store.business_id == business_id).where(Store.is_deleted == False)  # noqa: E712
        )
    ).all()
    return list(stores)


@router.post(
    "/{business_id}/stores",
    response_model=StoreRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_store_endpoint(
    business_id: UUID,
    body: StoreCreate,
    db: AsyncSession = Depends(get_async_session),
    caller_business_id: str = Depends(require_business_permission(PermissionCode.STORES_CREATE)),
) -> Store:
    _require_context_match(business_id, caller_business_id)

    async with db.begin():
        business = await _get_business_or_404(db, business_id)
        try:
            validate_store_type(business.business_type, body.location_type.value)
        except InvalidStoreTypeError as exc:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail=str(exc),
            ) from None

        store = Store(
            business_id=business.id,
            name=body.name,
            token=generate_store_token(),
            location_type=body.location_type,
            status=body.status,
            country_code=body.country_code,
            city=body.city,
            address=body.address,
            timezone=body.timezone,
            is_primary=body.is_primary,
        )
        db.add(store)
        await db.flush()
        db.add(StoreSetting(store_id=store.id, active=True))

    await db.refresh(store)
    return store


@router.get("/{business_id}/stores/{store_id}", response_model=StoreRead)
async def get_store(
    business_id: UUID,
    store_id: UUID,
    db: AsyncSession = Depends(get_async_session),
    caller_business_id: str = Depends(require_business_context()),
) -> Store:
    _require_context_match(business_id, caller_business_id)
    return await _get_store_or_404(db, business_id, store_id)


@router.patch("/{business_id}/stores/{store_id}", response_model=StoreRead)
async def update_store(
    business_id: UUID,
    store_id: UUID,
    body: StoreUpdate,
    db: AsyncSession = Depends(get_async_session),
    caller_business_id: str = Depends(require_business_permission(PermissionCode.STORES_UPDATE)),
) -> Store:
    _require_context_match(business_id, caller_business_id)

    values = body.model_dump(exclude_unset=True)
    if "location_type" in values:
        business = await _get_business_or_404(db, business_id)
        try:
            validate_store_type(business.business_type, values["location_type"].value)
        except InvalidStoreTypeError as exc:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
                detail=str(exc),
            ) from None

    async with db.begin():
        store = await _get_store_or_404(db, business_id, store_id)
        _apply_update(store, values)
        db.add(store)

    await db.refresh(store)
    return store


# ── Store settings (1:1 with store; no standalone POST) ──────────────────


@router.get("/{business_id}/stores/{store_id}/settings", response_model=StoreSettingRead)
async def get_store_settings(
    business_id: UUID,
    store_id: UUID,
    db: AsyncSession = Depends(get_async_session),
    caller_business_id: str = Depends(require_business_context()),
) -> StoreSetting:
    _require_context_match(business_id, caller_business_id)
    await _get_store_or_404(db, business_id, store_id)

    setting = (
        await db.exec(select(StoreSetting).where(StoreSetting.store_id == store_id))
    ).one_or_none()
    if setting is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Store settings not found",
        )
    return setting


@router.patch("/{business_id}/stores/{store_id}/settings", response_model=StoreSettingRead)
async def update_store_settings(
    business_id: UUID,
    store_id: UUID,
    body: StoreSettingUpdate,
    db: AsyncSession = Depends(get_async_session),
    caller_business_id: str = Depends(require_business_permission(PermissionCode.STORES_UPDATE)),
) -> StoreSetting:
    _require_context_match(business_id, caller_business_id)
    await _get_store_or_404(db, business_id, store_id)

    values = body.model_dump(exclude_unset=True)

    async with db.begin():
        setting = (
            await db.exec(select(StoreSetting).where(StoreSetting.store_id == store_id))
        ).one_or_none()
        if setting is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Store settings not found",
            )
        _apply_update(setting, values)
        db.add(setting)

    await db.refresh(setting)
    return setting
