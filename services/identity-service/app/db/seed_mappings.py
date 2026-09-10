"""Mapping for permission codes referenced by the agreed seed plan but absent
from the reconciled PermissionCode enum.

The ``PermissionCode`` enum is shared and reconciled across all three services.
One POS code in the agreed seed plan does not exist in it as a distinct
concept — "sync" is just the write action:

    POS_SALES_SYNC             -> POS_WRITE

(The equivalent inventory mapping — INVENTORY_WASTE_RECORD/TRANSFER/
ITEMS_CREATE/ITEMS_UPDATE/ITEMS_DEACTIVATE collapsing onto INVENTORY_ADJUST —
was removed for the same reason ``POS_SALES_VIEW``/``POS_SALES_LIST``
collapsing onto ``POS_WRITE`` was removed below: pos-service's read endpoints
(list sales, sale detail, sales summary) enforce a distinct ``pos.view`` code,
so collapsing "view"/"list" onto "write" meant those endpoints were
permanently 403 for every role *and* granted POS-sync (write) access to
internal read-only roles like Finance/Data Analyst that only asked for
"view"/"list". ``POS_VIEW`` is now a first-class ``PermissionCode`` member
and is referenced directly from ``app/db/seed_role_templates.py`` and
``app/db/seed_internal_rbac.py``.)

This is a data-seeding convenience only.  Seed modules reference the named
constants below so the intended (deprecated) vocabulary stays visible alongside
the code actually written to the database.
"""

from collections.abc import Iterable

from app.core.permission_codes import PermissionCode

# --- Named resolution constants (deprecated -> existing) ---
POS_SALES_SYNC = PermissionCode.POS_WRITE

# --- Machine-readable mapping (documentation/audit) ----------------------------
RESOLVED_MAPPING: dict[str, PermissionCode] = {
    "pos.sales.sync": PermissionCode.POS_WRITE,
}


def uniq(codes: Iterable[PermissionCode]) -> tuple[PermissionCode, ...]:
    """Return ``codes`` order-preserved with duplicates removed.

    Mapping several deprecated codes onto one existing code can legitimately
    produce duplicates in a definition; the PK of the role/template permission
    rows makes duplicates invalid, so dedupe before writing.
    """
    return tuple(dict.fromkeys(codes))
