"""Unit tests for item schemas — validation, field exclusion, and enum enforcement."""

from decimal import Decimal
from uuid import UUID

import pytest
from pydantic import ValidationError

from app.schemas.items import ItemCreate, ItemRead, ItemUpdate


class TestItemCreate:
    def test_valid_create_succeeds(self) -> None:
        data = ItemCreate(
            name="Fresh Tomatoes",
            unit_of_measure="kg",
            item_type="both",
            reorder_threshold=10.0,
            reorder_quantity=50.0,
            store_id=UUID("22222222-2222-2222-2222-222222222222"),
        )
        assert data.name == "Fresh Tomatoes"
        assert data.store_id == UUID("22222222-2222-2222-2222-222222222222")
        assert data.selling_price is None

    def test_valid_create_with_selling_price_succeeds(self) -> None:
        data = ItemCreate(
            name="Jollof Rice",
            unit_of_measure="unit",
            item_type="sellable",
            reorder_threshold=10.0,
            reorder_quantity=50.0,
            selling_price=25.5,
            store_id=UUID("22222222-2222-2222-2222-222222222222"),
        )
        assert data.selling_price == 25.5

    def test_rejects_invalid_unit_of_measure(self) -> None:
        with pytest.raises(ValidationError):
            ItemCreate(
                name="Bad Unit Item",
                unit_of_measure="stone",  # not in UnitOfMeasure enum
                reorder_threshold=5.0,
                reorder_quantity=20.0,
                business_id=UUID("11111111-1111-1111-1111-111111111111"),
                store_id=UUID("22222222-2222-2222-2222-222222222222"),
            )

    def test_rejects_invalid_item_type(self) -> None:
        with pytest.raises(ValidationError):
            ItemCreate(
                name="Bad Type Item",
                unit_of_measure="kg",
                item_type="discontinued",  # not in ItemType enum
                reorder_threshold=5.0,
                reorder_quantity=20.0,
                business_id=UUID("11111111-1111-1111-1111-111111111111"),
                store_id=UUID("22222222-2222-2222-2222-222222222222"),
            )


class TestItemUpdate:
    def test_all_fields_optional(self) -> None:
        data = ItemUpdate()
        assert data.model_dump(exclude_unset=True) == {}

    def test_excludes_business_id_and_store_id(self) -> None:
        assert not hasattr(ItemUpdate.model_fields, "business_id")
        assert not hasattr(ItemUpdate.model_fields, "store_id")

    def test_partial_update_works(self) -> None:
        data = ItemUpdate(name="Renamed Item")
        assert data.name == "Renamed Item"
        assert data.unit_of_measure is None
        assert data.category is None

    def test_update_selling_price_works(self) -> None:
        data = ItemUpdate(selling_price=Decimal("29.99"))
        assert data.selling_price == Decimal("29.99")
        assert "selling_price" in data.model_dump(exclude_unset=True)


class TestItemRead:
    def test_iterface_fields(self) -> None:
        """Confirm ItemRead has the expected fields via attribute access."""
        fields = set(ItemRead.model_fields.keys())
        assert "id" in fields
        assert "business_id" in fields
        assert "name" in fields
        assert "selling_price" in fields
        assert "is_active" in fields
        assert "created_at" in fields
        assert "updated_at" in fields