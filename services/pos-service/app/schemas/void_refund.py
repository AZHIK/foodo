"""Void/refund request schema — for after-the-fact actions against already-synced sales.

A sale that arrived as ``completed`` may later be voided or refunded
through a separate endpoint (while online, or via a future sync action).
This schema is distinct from ``SaleSyncInput`` because it targets an
existing sale rather than creating a new one.
"""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class VoidRefundRequest(BaseModel):
    """Request to void or refund an already-synced ``completed`` sale.

    ``client_action_id`` is the idempotency key for this specific action
    (distinct from the sale's ``client_sale_id``, since the same sale
    could be voided or refunded multiple times across different offline
    sessions).

    ``reason`` is required — void/refund actions always require a reason.
    """

    client_action_id: str
    new_status: Literal["voided", "refunded"]
    reason: str = Field(min_length=1)
