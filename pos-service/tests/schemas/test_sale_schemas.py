"""Schema validation tests — input constraints enforced at the Pydantic layer."""

from datetime import UTC, datetime
from decimal import Decimal
from uuid import uuid4

import pytest
from pydantic import ValidationError

from app.schemas.line_items import SaleLineItemInput
from app.schemas.sales import SaleSyncBatchRequest, SaleSyncInput
from app.schemas.void_refund import VoidRefundRequest


class TestSaleLineItemInput:
    """``quantity`` and ``unit_price`` must be strictly positive."""

    def test_zero_quantity_rejected(self) -> None:
        with pytest.raises(ValidationError):
            SaleLineItemInput(
                item_id=uuid4(),
                quantity=Decimal("0"),
                unit_price=Decimal("10.00"),
            )

    def test_negative_quantity_rejected(self) -> None:
        with pytest.raises(ValidationError):
            SaleLineItemInput(
                item_id=uuid4(),
                quantity=Decimal("-1"),
                unit_price=Decimal("10.00"),
            )

    def test_zero_unit_price_rejected(self) -> None:
        with pytest.raises(ValidationError):
            SaleLineItemInput(
                item_id=uuid4(),
                quantity=Decimal("2"),
                unit_price=Decimal("0"),
            )

    def test_negative_unit_price_rejected(self) -> None:
        with pytest.raises(ValidationError):
            SaleLineItemInput(
                item_id=uuid4(),
                quantity=Decimal("2"),
                unit_price=Decimal("-5.00"),
            )

    def test_valid_input_accepted(self) -> None:
        item = SaleLineItemInput(
            item_id=uuid4(),
            quantity=Decimal("2"),
            unit_price=Decimal("10.00"),
        )
        assert item.quantity == Decimal("2")
        assert item.unit_price == Decimal("10.00")
        assert item.discount_amount == Decimal("0")


class TestSaleSyncInput:
    """Conditional requirements and structural validation."""

    def test_voided_without_reason_rejected(self) -> None:
        with pytest.raises(ValidationError, match="void_or_refund_reason"):
            SaleSyncInput(
                client_sale_id="void-no-reason",
                status="voided",
                business_location_id=uuid4(),
                line_items=[
                    SaleLineItemInput(
                        item_id=uuid4(),
                        quantity=Decimal("1"),
                        unit_price=Decimal("5.00"),
                    )
                ],
                payment_method="cash",
                occurred_at=datetime.now(UTC),
            )

    def test_refunded_without_reason_rejected(self) -> None:
        with pytest.raises(ValidationError, match="void_or_refund_reason"):
            SaleSyncInput(
                client_sale_id="refund-no-reason",
                status="refunded",
                business_location_id=uuid4(),
                line_items=[
                    SaleLineItemInput(
                        item_id=uuid4(),
                        quantity=Decimal("1"),
                        unit_price=Decimal("5.00"),
                    )
                ],
                payment_method="cash",
                occurred_at=datetime.now(UTC),
            )

    def test_empty_line_items_rejected(self) -> None:
        with pytest.raises(ValidationError):
            SaleSyncInput(
                client_sale_id="empty-line-items",
                status="completed",
                business_location_id=uuid4(),
                line_items=[],
                payment_method="cash",
                occurred_at=datetime.now(UTC),
            )

    def test_pre_voided_with_reason_accepted(self) -> None:
        """A sale born already-voided (never completed on server) is valid MVP behavior."""
        sale = SaleSyncInput(
            client_sale_id="pre-voided",
            status="voided",
            business_location_id=uuid4(),
            line_items=[
                SaleLineItemInput(
                    item_id=uuid4(),
                    quantity=Decimal("1"),
                    unit_price=Decimal("10.00"),
                )
            ],
            payment_method="card",
            occurred_at=datetime.now(UTC),
            void_or_refund_reason="Cashier error before sync",
        )
        assert sale.status == "voided"
        assert sale.void_or_refund_reason == "Cashier error before sync"

    def test_valid_completed_sale_accepted(self) -> None:
        sale = SaleSyncInput(
            client_sale_id="valid-sale",
            status="completed",
            business_location_id=uuid4(),
            line_items=[
                SaleLineItemInput(
                    item_id=uuid4(),
                    quantity=Decimal("3"),
                    unit_price=Decimal("15.00"),
                    discount_amount=Decimal("2.00"),
                )
            ],
            discount_amount=Decimal("2.00"),
            payment_method="mobile_money",
            occurred_at=datetime.now(UTC),
            device_sequence=42,
        )
        assert sale.client_sale_id == "valid-sale"
        assert sale.device_sequence == 42


class TestSaleSyncBatchRequest:
    """Batch-level structural validation."""

    def test_empty_sales_list_rejected(self) -> None:
        with pytest.raises(ValidationError):
            SaleSyncBatchRequest(sales=[])


class TestVoidRefundRequest:
    """Void/refund action schema — reason is required."""

    def test_empty_reason_rejected(self) -> None:
        with pytest.raises(ValidationError):
            VoidRefundRequest(
                client_action_id="action-001",
                new_status="voided",
                reason="",
            )

    def test_valid_request_accepted(self) -> None:
        req = VoidRefundRequest(
            client_action_id="action-001",
            new_status="voided",
            reason="Customer changed mind",
        )
        assert req.client_action_id == "action-001"
        assert req.new_status == "voided"
        assert req.reason == "Customer changed mind"
