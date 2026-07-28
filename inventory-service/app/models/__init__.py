"""SQLModel table=True models for FoodLink Inventory Service.

Each model defined here inherits from SQLModel and has table=True,
meaning it maps to a Postgres table.

Import all models here so SQLModel.metadata is complete for Alembic.
"""

from app.models.inventory import (
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

__all__ = [
    "ActorType",
    "Item",
    "ItemType",
    "MovementType",
    "ProcessedEvent",
    "RecipeComponent",
    "StockLevel",
    "StockMovement",
    "UnitOfMeasure",
]