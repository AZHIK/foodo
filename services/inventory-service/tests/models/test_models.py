"""Model tests — instantiation shape, FK enforcement, unique constraint, numeric precision.

Stage 2 tests: model classes are instantiated to confirm required fields
exist and relationships are wired.  Persistence tests (FK enforcement,
unique constraint, numeric drift) use the real Postgres test database via
the ``db_session`` fixture.
"""

from __future__ import annotations

from datetime import UTC, datetime
from decimal import Decimal
from uuid import UUID

import pytest
from sqlalchemy.exc import IntegrityError
from sqlmodel.ext.asyncio.session import AsyncSession

from app.models import (
    ActorType,
    Item,
    ItemType,
    MovementType,
    ProcessedEvent,
    RecipeComponent,
    StockLevel,
    StockMovement,
    UnitOfMeasure,
)


# ═══════════════════════════════════════════════════════════════════════
# Instantiation shape tests (no DB required)
# ═══════════════════════════════════════════════════════════════════════


class TestItemModel:
    def test_create_item_minimal(self) -> None:
        item = Item(
            business_id=UUID("00000000-0000-0000-0000-000000000001"),
            business_location_id=UUID("00000000-0000-0000-0000-000000000002"),
            name="Fresh Tomatoes",
            unit_of_measure=UnitOfMeasure.KG,
            item_type=ItemType.BOTH,
            reorder_threshold=Decimal("10.000"),
            reorder_quantity=Decimal("50.000"),
        )
        assert isinstance(item.id, UUID)
        assert item.business_id == UUID("00000000-0000-0000-0000-000000000001")
        assert item.name == "Fresh Tomatoes"
        assert item.unit_of_measure == UnitOfMeasure.KG
        assert item.reorder_threshold == Decimal("10.000")
        assert item.selling_price is None
        assert item.allow_negative_stock is False
        assert item.item_type == ItemType.BOTH
        assert item.is_active is True
        assert item.category is None
        assert isinstance(item.created_at, datetime)
        assert isinstance(item.updated_at, datetime)

    def test_create_item_with_selling_price(self) -> None:
        item = Item(
            business_id=UUID("00000000-0000-0000-0000-000000000001"),
            business_location_id=UUID("00000000-0000-0000-0000-000000000002"),
            name="Jollof Rice",
            unit_of_measure=UnitOfMeasure.UNIT,
            item_type=ItemType.SELLABLE,
            reorder_threshold=Decimal("10.000"),
            reorder_quantity=Decimal("50.000"),
            selling_price=Decimal("12.99"),
        )
        assert item.selling_price == Decimal("12.99")

    def test_selling_price_allowed_on_raw_material(self) -> None:
        """raw_material items may carry a selling_price (unconstrained)."""
        item = Item(
            business_id=UUID("00000000-0000-0000-0000-000000000001"),
            business_location_id=UUID("00000000-0000-0000-0000-000000000002"),
            name="Flour",
            unit_of_measure=UnitOfMeasure.KG,
            item_type=ItemType.RAW_MATERIAL,
            reorder_threshold=Decimal("10.000"),
            reorder_quantity=Decimal("50.000"),
            selling_price=Decimal("5.50"),
        )
        assert item.item_type == ItemType.RAW_MATERIAL
        assert item.selling_price == Decimal("5.50")

    def test_item_type_enum_values(self) -> None:
        assert ItemType.SELLABLE.value == "sellable"
        assert ItemType.RAW_MATERIAL.value == "raw_material"
        assert ItemType.BOTH.value == "both"

    def test_unit_of_measure_enum_values(self) -> None:
        assert UnitOfMeasure.KG.value == "kg"
        assert UnitOfMeasure.G.value == "g"
        assert UnitOfMeasure.L.value == "l"
        assert UnitOfMeasure.ML.value == "ml"
        assert UnitOfMeasure.UNIT.value == "unit"
        assert UnitOfMeasure.PACK.value == "pack"


class TestRecipeComponentModel:
    def test_create_recipe_component(self) -> None:
        rc = RecipeComponent(
            sellable_item_id=UUID("00000000-0000-0000-0000-000000000001"),
            raw_material_item_id=UUID("00000000-0000-0000-0000-000000000002"),
            quantity_required=Decimal("2.500"),
        )
        assert isinstance(rc.id, UUID)
        assert rc.quantity_required == Decimal("2.500")


class TestStockLevelModel:
    def test_create_stock_level(self) -> None:
        sl = StockLevel(
            item_id=UUID("00000000-0000-0000-0000-000000000001"),
            business_location_id=UUID("00000000-0000-0000-0000-000000000002"),
            current_quantity=Decimal("100.000"),
        )
        assert isinstance(sl.id, UUID)
        assert sl.current_quantity == Decimal("100.000")
        assert isinstance(sl.updated_at, datetime)


class TestStockMovementModel:
    def test_create_stock_movement(self) -> None:
        sm = StockMovement(
            item_id=UUID("00000000-0000-0000-0000-000000000001"),
            business_id=UUID("00000000-0000-0000-0000-000000000002"),
            business_location_id=UUID("00000000-0000-0000-0000-000000000003"),
            quantity_delta=Decimal("-5.000"),
            movement_type=MovementType.SALE,
            actor_type=ActorType.USER,
            actor_id=UUID("00000000-0000-0000-0000-000000000004"),
            reason="Customer walked in purchase",
        )
        assert isinstance(sm.id, UUID)
        assert sm.quantity_delta == Decimal("-5.000")
        assert sm.movement_type == MovementType.SALE
        assert sm.actor_type == ActorType.USER
        assert sm.reference_type is None
        assert sm.reference_id is None

    def test_movement_type_enum_values(self) -> None:
        assert MovementType.SALE.value == "sale"
        assert MovementType.PURCHASE_RECEIVED.value == "purchase_received"
        assert MovementType.MANUAL_ADJUSTMENT.value == "manual_adjustment"
        assert MovementType.WASTE.value == "waste"
        assert MovementType.TRANSFER_IN.value == "transfer_in"
        assert MovementType.TRANSFER_OUT.value == "transfer_out"

    def test_actor_type_enum_values(self) -> None:
        assert ActorType.USER.value == "user"
        assert ActorType.SYSTEM.value == "system"
        assert ActorType.SERVICE.value == "service"


class TestProcessedEventModel:
    def test_create_processed_event(self) -> None:
        pe = ProcessedEvent(event_id="evt-abc-123")
        assert pe.event_id == "evt-abc-123"
        assert isinstance(pe.processed_at, datetime)


# ═══════════════════════════════════════════════════════════════════════
# Persistence tests (require DB)
# ═══════════════════════════════════════════════════════════════════════


class TestPersistence:
    """Tests that exercise the database — FK enforcement, unique constraint, numeric precision."""

    async def _create_item(self, session: AsyncSession, suffix: str = "") -> Item:
        item = Item(
            business_id=UUID("00000000-0000-0000-0000-000000000001"),
            business_location_id=UUID("00000000-0000-0000-0000-000000000002"),
            name=f"Test Item{suffix}",
            unit_of_measure=UnitOfMeasure.KG,
            item_type=ItemType.BOTH,
            reorder_threshold=Decimal("10.000"),
            reorder_quantity=Decimal("50.000"),
        )
        session.add(item)
        await session.commit()
        await session.refresh(item)
        return item

    async def test_item_can_be_persisted_and_read_back(self, db_session: AsyncSession) -> None:
        item = await self._create_item(db_session)
        assert item.name == "Test Item"
        assert item.id is not None
        assert item.created_at is not None
        assert item.updated_at is not None

    async def test_stock_levels_unique_constraint_enforced(
        self, db_session: AsyncSession
    ) -> None:
        """Verify the (item_id, business_location_id) unique constraint is load-bearing."""
        item = await self._create_item(db_session)
        biz_loc = UUID("00000000-0000-0000-0000-000000000002")

        sl1 = StockLevel(
            item_id=item.id,
            business_location_id=biz_loc,
            current_quantity=Decimal("100.000"),
        )
        db_session.add(sl1)
        await db_session.commit()

        sl2 = StockLevel(
            item_id=item.id,
            business_location_id=biz_loc,
            current_quantity=Decimal("200.000"),
        )
        db_session.add(sl2)
        with pytest.raises(IntegrityError):
            await db_session.commit()
        await db_session.rollback()

    async def test_selling_price_numeric_round_trip(self, db_session: AsyncSession) -> None:
        """Confirm selling_price survives a round-trip without floating-point drift."""
        item = Item(
            business_id=UUID("00000000-0000-0000-0000-000000000001"),
            business_location_id=UUID("00000000-0000-0000-0000-000000000002"),
            name="Precision Priced Item",
            unit_of_measure=UnitOfMeasure.UNIT,
            item_type=ItemType.BOTH,
            reorder_threshold=Decimal("10.000"),
            reorder_quantity=Decimal("50.000"),
            selling_price=Decimal("0.1") + Decimal("0.2"),
        )
        db_session.add(item)
        await db_session.commit()
        await db_session.refresh(item)

        assert item.selling_price == Decimal("0.3")
        assert item.selling_price == Decimal("0.1") + Decimal("0.2")

    async def test_selling_price_none_persists_as_null(self, db_session: AsyncSession) -> None:
        """An item without a selling_price stores NULL — genuinely optional."""
        item = await self._create_item(db_session)
        assert item.selling_price is None

    async def test_numeric_precision_round_trip(self, db_session: AsyncSession) -> None:
        """Confirm Decimal quantities survive a round-trip without floating-point drift.

        The classic 0.1 + 0.2 test — if stored as float this would yield
        0.30000000000000004; stored as Decimal/Numeric it must return
        exactly 0.3.
        """
        item = await self._create_item(db_session)
        biz_loc = UUID("00000000-0000-0000-0000-000000000002")

        precision_test_value = Decimal("0.1") + Decimal("0.2")
        assert precision_test_value == Decimal("0.3")

        sl = StockLevel(
            item_id=item.id,
            business_location_id=biz_loc,
            current_quantity=precision_test_value,
        )
        db_session.add(sl)
        await db_session.commit()
        await db_session.refresh(sl)

        assert sl.current_quantity == Decimal("0.3")
        assert sl.current_quantity == precision_test_value

    async def test_fk_enforced_for_stock_movement(self, db_session: AsyncSession) -> None:
        """Inserting a stock_movement referencing a non-existent item_id fails."""
        sm = StockMovement(
            item_id=UUID("00000000-0000-0000-0000-000000009999"),
            business_id=UUID("00000000-0000-0000-0000-000000000002"),
            business_location_id=UUID("00000000-0000-0000-0000-000000000003"),
            quantity_delta=Decimal("-5.000"),
            movement_type=MovementType.SALE,
            actor_type=ActorType.USER,
        )
        db_session.add(sm)
        with pytest.raises(IntegrityError):
            await db_session.commit()
        await db_session.rollback()

    async def test_fk_enforced_for_stock_level(self, db_session: AsyncSession) -> None:
        """Inserting a stock_level with a non-existent item_id fails."""
        sl = StockLevel(
            item_id=UUID("00000000-0000-0000-0000-000000009999"),
            business_location_id=UUID("00000000-0000-0000-0000-000000000002"),
            current_quantity=Decimal("50.000"),
        )
        db_session.add(sl)
        with pytest.raises(IntegrityError):
            await db_session.commit()
        await db_session.rollback()

    async def test_fk_enforced_for_recipe_component(self, db_session: AsyncSession) -> None:
        """Inserting a recipe_component with a non-existent sellable_item_id fails."""
        rc = RecipeComponent(
            sellable_item_id=UUID("00000000-0000-0000-0000-000000009999"),
            raw_material_item_id=UUID("00000000-0000-0000-0000-000000009998"),
            quantity_required=Decimal("2.500"),
        )
        db_session.add(rc)
        with pytest.raises(IntegrityError):
            await db_session.commit()
        await db_session.rollback()

    async def test_cross_service_columns_accept_any_uuid(self, db_session: AsyncSession) -> None:
        """business_id and business_location_id are plain UUIDs — no FK enforced."""
        item = Item(
            business_id=UUID("ffffffff-ffff-ffff-ffff-ffffffffffff"),
            business_location_id=UUID("eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"),
            name="Cross-Service Item",
            unit_of_measure=UnitOfMeasure.UNIT,
            item_type=ItemType.BOTH,
            reorder_threshold=Decimal("5.000"),
            reorder_quantity=Decimal("20.000"),
        )
        db_session.add(item)
        await db_session.commit()
        await db_session.refresh(item)
        assert item.business_id == UUID("ffffffff-ffff-ffff-ffff-ffffffffffff")
        assert item.business_location_id == UUID("eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")

    async def test_stock_movement_cascade_delete(self, db_session: AsyncSession) -> None:
        """Deleting an item cascades to its stock_movements."""
        item = await self._create_item(db_session)

        sm = StockMovement(
            item_id=item.id,
            business_id=UUID("00000000-0000-0000-0000-000000000002"),
            business_location_id=UUID("00000000-0000-0000-0000-000000000003"),
            quantity_delta=Decimal("-5.000"),
            movement_type=MovementType.SALE,
            actor_type=ActorType.USER,
        )
        db_session.add(sm)
        await db_session.commit()

        await db_session.delete(item)
        await db_session.commit()

        from sqlmodel import select

        result = await db_session.exec(select(StockMovement).where(StockMovement.item_id == item.id))
        assert result.first() is None