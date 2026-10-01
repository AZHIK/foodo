from __future__ import annotations

from uuid import UUID

from sqlalchemy import func as sa_func
from sqlalchemy import or_ as sa_or
from sqlalchemy.exc import IntegrityError
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.exceptions import DomainError
from app.models.couriers import Courier
from app.schemas.couriers import CourierCreate, CourierListResponse, CourierRead, CourierUpdate


class CourierServiceError(DomainError):
    """Base for all courier service errors."""


class CourierValidationError(CourierServiceError):
    """A courier's input data fails business-rule validation."""


class CourierNotFoundError(CourierServiceError):
    """Raised when a courier doesn't exist (or doesn't belong to the business)."""


class CourierConflictError(CourierServiceError):
    """Raised when a courier phone is already in use for the business."""


def _to_read(courier: Courier) -> CourierRead:
    return CourierRead(
        id=courier.id,
        business_id=courier.business_id,
        name=courier.name,
        phone=courier.phone,
        vehicle=courier.vehicle,
        is_active=courier.is_active,
        actor_id=courier.actor_id,
        created_at=courier.created_at,
        updated_at=courier.updated_at,
    )


async def create_courier(
    session: AsyncSession,
    business_id: UUID,
    actor_id: UUID | None,
    payload: CourierCreate,
) -> Courier:
    """Create a courier; phone must be unique within the business."""
    existing = (
        await session.exec(
            select(Courier).where(
                Courier.business_id == business_id,
                Courier.phone == payload.phone,
            )
        )
    ).first()
    if existing is not None:
        raise CourierConflictError(
            f"Courier phone {payload.phone} is already in use for this business"
        )

    courier = Courier(
        business_id=business_id,
        name=payload.name,
        phone=payload.phone,
        vehicle=payload.vehicle,
        is_active=payload.is_active,
        actor_id=actor_id,
    )
    session.add(courier)
    try:
        await session.flush()
    except IntegrityError as exc:
        raise CourierConflictError(
            f"Courier phone {payload.phone} is already in use for this business"
        ) from exc
    await session.commit()
    return courier


async def list_couriers(
    session: AsyncSession,
    business_id: UUID,
    *,
    limit: int,
    offset: int,
    search: str | None = None,
    active_only: bool = False,
) -> CourierListResponse:
    """Paginated courier list, optionally searched by name/phone."""
    where_clauses = [Courier.business_id == business_id]
    if active_only:
        where_clauses.append(Courier.is_active.is_(True))  # type: ignore[attr-defined]
    if search:
        pattern = f"%{search}%"
        where_clauses.append(sa_or(Courier.name.ilike(pattern), Courier.phone.ilike(pattern)))

    count_stmt = select(sa_func.count()).select_from(
        select(Courier.id).where(*where_clauses).subquery()
    )
    total = (await session.exec(count_stmt)).one()

    stmt = (
        select(Courier)
        .where(*where_clauses)
        .order_by(Courier.name.asc())
        .offset(offset)
        .limit(limit)
    )
    couriers = (await session.exec(stmt)).all()

    return CourierListResponse(
        items=[_to_read(c) for c in couriers],
        total=total,
        limit=limit,
        offset=offset,
    )


async def get_courier(
    session: AsyncSession,
    business_id: UUID,
    courier_id: UUID,
) -> Courier:
    """Load a courier scoped to the business, or raise not-found."""
    courier = (
        await session.exec(
            select(Courier).where(
                Courier.id == courier_id,
                Courier.business_id == business_id,
            )
        )
    ).first()
    if courier is None:
        raise CourierNotFoundError(f"Courier {courier_id} not found for business {business_id}")
    return courier


async def update_courier(
    session: AsyncSession,
    business_id: UUID,
    courier_id: UUID,
    patch: CourierUpdate,
) -> Courier:
    """Partial update; a phone change re-checks per-business uniqueness."""
    courier = await get_courier(session, business_id, courier_id)

    update_data = patch.model_dump(exclude_unset=True)
    new_phone = update_data.get("phone")
    if new_phone is not None and new_phone != courier.phone:
        clash = (
            await session.exec(
                select(Courier).where(
                    Courier.business_id == business_id,
                    Courier.phone == new_phone,
                )
            )
        ).first()
        if clash is not None:
            raise CourierConflictError(
                f"Courier phone {new_phone} is already in use for this business"
            )

    for field, value in update_data.items():
        setattr(courier, field, value)

    session.add(courier)
    try:
        await session.flush()
    except IntegrityError as exc:
        raise CourierConflictError("Courier phone is already in use for this business") from exc
    await session.commit()
    # `updated_at` is server-computed (onupdate=func.now()), so SQLAlchemy
    # expires it on flush — refresh here so the caller's later synchronous
    # attribute reads don't trigger an implicit lazy-load outside the async
    # context (MissingGreenlet). Same pattern as update_customer.
    await session.refresh(courier)
    return courier


async def delete_courier(
    session: AsyncSession,
    business_id: UUID,
    courier_id: UUID,
) -> None:
    """Delete a courier; linked sales keep their rows with courier_id=NULL.

    Relies on the ``ON DELETE SET NULL`` FK from ``sales.courier_id`` —
    no sale rows are touched here explicitly.
    """
    courier = await get_courier(session, business_id, courier_id)
    await session.delete(courier)
    await session.commit()


async def validate_courier_for_sale(
    session: AsyncSession,
    business_id: UUID,
    courier_id: UUID,
) -> Courier:
    """Guard used by ``sale_service``: courier must exist, belong to the
    business, and be active. Defined here (not imported from sale_service)
    to avoid a circular import — ``sale_service`` imports this module.
    """
    courier = (await session.exec(select(Courier).where(Courier.id == courier_id))).first()
    if courier is None or courier.business_id != business_id:
        raise CourierValidationError("courier_id does not exist for this business")
    if not courier.is_active:
        raise CourierValidationError("courier_id refers to an inactive courier")
    return courier
