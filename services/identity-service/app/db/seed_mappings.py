"""Mapping for permission codes referenced by the agreed seed plan but absent
from the reconciled PermissionCode enum.

The ``PermissionCode`` enum is shared and reconciled across all three services.
Three POS codes in the agreed seed plan do not exist in it (the enum exposes
only ``POS_WRITE``/``POS_REFUND`` for the POS domain). Per the stakeholder
decision we map each absent code onto the closest existing action code:

    POS_SALES_SYNC             -> POS_WRITE
    POS_SALES_VIEW             -> POS_WRITE
    POS_SALES_LIST             -> POS_WRITE

(The equivalent inventory mapping — INVENTORY_WASTE_RECORD/TRANSFER/
ITEMS_CREATE/ITEMS_UPDATE/ITEMS_DEACTIVATE collapsing onto INVENTORY_ADJUST —
was removed: inventory-service enforces these as distinct permission codes on
its write endpoints, so collapsing them here meant a token could never carry
the exact code an endpoint required, and every inventory write 403'd
regardless of role. Those five codes are now first-class ``PermissionCode``
members and are referenced directly from ``app/db/seed_role_templates.py``.)

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

# --- Machine-readable mapping (documentation/audit) ----------------------------
RESOLVED_MAPPING: dict[str, PermissionCode] = {
    "pos.sales.sync": PermissionCode.POS_WRITE,
    "pos.sales.view": PermissionCode.POS_WRITE,
    "pos.sales.list": PermissionCode.POS_WRITE,
}


def uniq(codes: Iterable[PermissionCode]) -> tuple[PermissionCode, ...]:
    """Return ``codes`` order-preserved with duplicates removed.

    Mapping several deprecated codes onto one existing code can legitimately
    produce duplicates in a definition; the PK of the role/template permission
    rows makes duplicates invalid, so dedupe before writing.
    """
    return tuple(dict.fromkeys(codes))
