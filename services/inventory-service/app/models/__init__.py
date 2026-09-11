"""SQLModel table=True models for FoodLink Inventory Service.

Each model defined here inherits from SQLModel and has table=True,
meaning it maps to a Postgres table.

Import all models here so SQLModel.metadata is complete for Alembic.
"""

from app.models.categories import Category
from app.models.inventory import (
    ActorType,
    Item,
    ItemType,
    MovementType,
    ProcessedEvent,
    RecipeComponent,
    StockLevel,
    StockMovement,
)
from app.models.reorders import Reorder, ReorderStatus
from app.models.suppliers import Supplier
from app.models.units import Unit

__all__ = [
    "ActorType",
    "Category",
    "Item",
    "ItemType",
    "MovementType",
    "ProcessedEvent",
    "RecipeComponent",
    "Reorder",
    "ReorderStatus",
    "StockLevel",
    "StockMovement",
    "Supplier",
    "Unit",
]