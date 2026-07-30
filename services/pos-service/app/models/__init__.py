"""SQLModel table=True models for FoodLink POS Service.

Each model defined here inherits from SQLModel and has table=True,
meaning it maps to a Postgres table.

Import all models here so SQLModel.metadata is complete for Alembic.
"""

from app.models.pos import (
    PaymentMethod,
    Sale,
    SaleLineItem,
    SaleStatus,
)

__all__ = [
    "PaymentMethod",
    "Sale",
    "SaleLineItem",
    "SaleStatus",
]
