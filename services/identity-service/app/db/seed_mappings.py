"""Mapping for permission codes referenced by the agreed seed plan but absent
from the reconciled PermissionCode enum.

The ``PermissionCode`` enum is shared and reconciled across all three services
and is intentionally NOT modified here.  Eight codes in the agreed seed plan do
not exist in it (the enum exposes only ``POS_WRITE``/``POS_REFUND`` for the POS
domain and ``INVENTORY_VIEW``/``INVENTORY_ADJUST`` for inventory).  Per the
stakeholder decision we keep the enum unchanged and map each absent code onto
the closest existing action code:

    POS_SALES_SYNC             -> POS_WRITE
    POS_SALES_VIEW             -> POS_WRITE
    POS_SALES_LIST             -> POS_WRITE
    INVENTORY_WASTE_RECORD     -> INVENTORY_ADJUST
    INVENTORY_TRANSFER         -> INVENTORY_ADJUST
    INVENTORY_ITEMS_CREATE     -> INVENTORY_ADJUST
    INVENTORY_ITEMS_UPDATE     -> INVENTORY_ADJUST
    INVENTORY_ITEMS_DEACTIVATE -> INVENTORY_ADJUST

This is a data-seeding convenience only.  Seed modules reference the named
constants below so the intended (deprecated) vocabulary stays visible alongside
the code actually written to the database.
"""

from collections.abc import Iterable

from app.core.permission_codes import PermissionCode

# --- Named resolution constants (deprecated -> existing) ---
POS_SALES_SYNC = PermissionCode.POS_WRITE
POS_SALES_VIEW = PermissionCode.POS_WRITE
POS_SALES_LIST = PermissionCode.POS_WRITE

INVENTORY_WASTE_RECORD = PermissionCode.INVENTORY_ADJUST
INVENTORY_TRANSFER = PermissionCode.INVENTORY_ADJUST
INVENTORY_ITEMS_CREATE = PermissionCode.INVENTORY_ADJUST
INVENTORY_ITEMS_UPDATE = PermissionCode.INVENTORY_ADJUST
INVENTORY_ITEMS_DEACTIVATE = PermissionCode.INVENTORY_ADJUST

# --- Machine-readable mapping (documentation/audit) ----------------------------
RESOLVED_MAPPING: dict[str, PermissionCode] = {
    "pos.sales.sync": PermissionCode.POS_WRITE,
    "pos.sales.view": PermissionCode.POS_WRITE,
    "pos.sales.list": PermissionCode.POS_WRITE,
    "inventory.waste_record": PermissionCode.INVENTORY_ADJUST,
    "inventory.transfer": PermissionCode.INVENTORY_ADJUST,
    "inventory.items.create": PermissionCode.INVENTORY_ADJUST,
    "inventory.items.update": PermissionCode.INVENTORY_ADJUST,
    "inventory.items.deactivate": PermissionCode.INVENTORY_ADJUST,
}


def uniq(codes: Iterable[PermissionCode]) -> tuple[PermissionCode, ...]:
    """Return ``codes`` order-preserved with duplicates removed.

    Mapping several deprecated codes onto one existing code can legitimately
    produce duplicates in a definition; the PK of the role/template permission
    rows makes duplicates invalid, so dedupe before writing.
    """
    return tuple(dict.fromkeys(codes))
