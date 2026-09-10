"""Schemas for the internal stock-events endpoint (service-to-service only).

Mirrors the event payload shape POS Service already builds in
``_publish_sale_events``/``void_or_refund_sale`` — see
``services/pos-service/app/core/events.py`` and
``services/pos-service/app/services/sale_service.py``.
"""

from __future__ import annotations

from decimal import Decimal
from typing import Literal
from uuid import UUID

from pydantic import BaseModel

EventType = Literal["sale.completed", "sale.voided", "sale.refunded"]
LineItemResultStatus = Literal["applied", "skipped", "failed"]


class StockEventLineItem(BaseModel):
    item_id: UUID
    quantity: Decimal


class StockEventRequest(BaseModel):
    event_type: EventType
    event_id: str
    store_id: UUID
    sale_id: UUID
    line_items: list[StockEventLineItem]


class LineItemResult(BaseModel):
    item_id: UUID
    status: LineItemResultStatus
    reason: str | None = None


class StockEventResponse(BaseModel):
    results: list[LineItemResult]
