# Requisition flow — unified order cart → per-supplier POs → WhatsApp payloads

Staff build ONE order (a **Requisition**) with items from multiple suppliers in a
dialog-based cart, then submit. The backend splits it into SEPARATE purchase
orders — one per supplier — and prepares a ready-to-send WhatsApp payload per PO.
No WhatsApp API is called in this pass; staff send manually via a `wa.me` deep link.

## Confirmed decisions (do not re-litigate silently)

| # | Question | Decision |
|---|----------|----------|
| 1 | Bulk-assign overwrite | Default **unassigned-only**; explicit **"override all" toggle** replaces existing per-item picks |
| 2 | `po_number` scheme | **Global sequential per business** (`PO-0001`, existing `uq_purchaseorder_business_po_number`) |
| 3 | Append-to-draft rule | **Same requisition only** — append to a `draft`/`payload_ready` PO from the same requisition+supplier, else create new |
| 4 | Stack | FastAPI + SQLModel + Postgres/Alembic (`inventory-service`); Flutter + Riverpod app. **Additive only** — see mapping notes below |
| 5 | Delivery date | **Per requisition** (single `expected_at`, copied to each PO) |
| 6 | Cart dismiss | **Client-side session only** — no server draft; dialog close preserves in-memory cart |

### Existing-schema mapping (Q4 adjustments)

- `Supplier.phone` is the legacy number field. Added nullable `whatsapp_number`
  (+ `contact_person`, `is_active`). Payload resolution: `whatsapp_number` → else
  `phone` → else skip payload (PO still created, UI shows "Add WhatsApp number").
  `is_active=False` = temporarily not ordering; `is_deleted=True` = retired.
- There was **no `SupplierItem` table** (`Item.supplier_id` holds one supplier).
  Added `supplieritem` (price, moq, lead_time_days, is_preferred) — `Item.supplier_id`
  untouched. Missing catalogue row ⇒ `price_unconfirmed=true`, never a block.
- `PurchaseOrder.status` keeps all legacy values (`draft…received`) for the classic
  GRN flow; requisition POs use the new additive values, created at `payload_ready`.
- Flutter: `Supplier.whatsappNumber` falls back to `phone` via `sendNumber`.
  The Drift `cached_suppliers` table does **not** yet carry the new columns
  (TODO below) — cached rows resolve through `phone` until it does.

## Backend (`services/inventory-service`)

Migration `n2b3c4d5e6f7` (revises `m1a2b3c4d5e6`): new `requisition`,
`requisitionline`, `supplieritem`, `suppliermessage` (+ 4 native enums);
`supplier` += `whatsapp_number/contact_person/is_active`;
`purchaseorder` += nullable `requisition_id` FK + `idempotency_key`, enum +=
`payload_ready/sent/confirmed/partially_fulfilled/fulfilled`;
`purchaseorderline` += `price_unconfirmed` (default false).

- `POST /businesses/{bid}/requisitions` — submit cart → split → payloads.
  Rejects lines with no `supplier_id` (422 naming the items); allows
  `price_unconfirmed` (flagged, not blocked); duplicate `(supplier,item)` pairs
  merge by summing qty; same item under two suppliers ⇒ two POs. One commit —
  all-or-nothing. Idempotent on `idempotency_key` (re-submit returns the graph).
- `POST /businesses/{bid}/requisitions/{id}/bulk-assign`
  (`scope: all_items|unassigned_items_only`, `overwrite: bool`) — idempotent,
  re-resolves prices from `supplieritem`.
- `POST …/requisitions/{id}/regenerate-payloads` — rebuild after line edits.
- `POST /businesses/{bid}/supplier-items` — catalogue upsert.
- `POST /businesses/{bid}/purchases/orders/{id}/mark-sent|mark-confirmed` —
  manual staff transitions (message row → `sent` alongside the PO).

### Bulk-assign overwrite rules

`unassigned_items_only` touches only supplier-less lines. `all_items` is still
safe by default: lines with a supplier are skipped unless `overwrite=true`
(the "Override items that already have a supplier" toggle). Both write the same
`RequisitionLine.supplier_id`; `supplier_assignment_source` records
`manual_per_item` vs `bulk_all` for display only.

### PO split logic

Group lines by `supplier_id` → per group, reuse a `draft`/`payload_ready` PO of
**this requisition+supplier** if present, else `PO-<next global seq>` →
write `PurchaseOrderLine`s (unit denormalized from item, `price_unconfirmed`
carried over) → `total_amount = Σ confirmed lines` (TBC lines excluded) →
`SupplierMessage(status='ready')` per PO unless the supplier has no number.

### Status rollup (pure, `rollup_requisition_status`)

All `confirmed/fulfilled/received` → **Confirmed** · all `cancelled` →
**Cancelled** · any terminal-ok + rest open → **Partially Confirmed** ·
any `sent` → **Sent** · else **Not sent**. Never stored; derived per read.

### Payload schema (per PO, `SupplierMessage.payload`)

`po_id, supplier{name, whatsapp_number}, message_type='purchase_order',
text_preview` (TBC lines marked `price TBC`), `structured_data{po_number,
restaurant_name, order_date, delivery_requested_date, items[{name, qty, unit,
unit_price, line_total, price_unconfirmed}], total, notes}`,
`deep_link = https://wa.me/<digits>?text=<url-encoded text_preview>`.
Money: `Decimal`-only, line = `qty×price → 2dp`, total = `Σ → 2dp`; the preview
renders those same quantized values. Status enums include `sent/delivered/read`
for forward-compat; nothing auto-advances past `ready` — only staff taps do.

## Frontend (`apps/restaurant_app`)

- `requisition_cart_dialog.dart` — the cart. Bottom sheet (mobile) / centered
  640px modal (tablet/desktop) via `Breakpoints` (`tablet: 600, desktop: 1024,
  maxContentWidth: 1600`). Pinned header + sticky bulk bar + pinned footer;
  list scrolls independently. `RequisitionCartButton` (with count badge) is the
  persistent trigger, wired next to "New order" on the Purchases tab.
- `widgets/dialogs/supplier_picker_dialog.dart` — nested picker used for both
  scopes. Bottom sheet (mobile) / 440px dialog with autofocus search (larger).
  Same component, same field, different scope.
- `requisition_order_screen.dart` — Option 2 UX: date, rollup chip, grand total;
  supplier cards (badge, lines, subtotal, per-card busy state). 1-col mobile →
  2/3-col grid ≥ tablet widths (`LayoutBuilder` + `Breakpoints.of`, layout-only).
  `launchUrl(externalApplication)`: native app on mobile, Web/app prompt on
  desktop. Inline "Did this send? [Mark as Sent]" after open; "Mark Confirmed"
  on reply. No PO numbers here.
- `requisition_export_screen.dart` — secondary route (`…/requisition/:id/export`):
  real PO numbers, timestamps, `SelectableText` previews, Copy + Share/print,
  price-TBC lines marked. Print-friendly single column, capped at
  `maxContentWidth`.
- Touch targets ≥44px on mobile/tablet; hover never required. Dialog routes give
  focus trap + Esc + focus return; picker search autofouses on non-mobile.
- Routes: `AppRoute.requisitionDetail(id)` (`/purchasing/requisition/:id`),
  `AppRoute.requisitionExport(id)` (`…/export`). i18n: all strings via
  `AppStrings.req*` (+ en/sw maps).

## Tests

Backend (`tests/test_requisitions.py`, 16 tests): bulk scopes/overwrite/
`price_unconfirmed`/idempotent rerun; split grouping, missing-supplier 422
naming items + rollback, TBC flagging, same-item-two-suppliers, duplicate-submit,
bad-item rollback; payload totals/rounding/URL-encoding/missing-number/phone
fallback; rollup table; full journey incl. mark-sent/confirmed; no-number PO.
Run: `DB_URL=…:5434/foodlink_inventory TEST_DB_URL=…:5434/foodlink_inventory_test
uv run --project . python -m pytest tests/test_requisitions.py tests/api/test_purchases.py -q`
(all green; `test_store_scope.py` failures are pre-existing reorder/permission
WIP, untouched by this change).

App (`test/requisition_cart_test.dart` 12 tests — cart state machine, submit,
`fromJson`/badges; `test/requisition_cart_dialog_test.dart` 6 tests — sheet vs
dialog per width, dismiss-preserves-cart, blocker copy, picker assign, Esc).
Run: `flutter test test/requisition_cart_test.dart test/requisition_cart_dialog_test.dart`.

## Cross-device QA checklist

- [ ] Cart: bottom sheet mobile (swipe dismiss, keyboard insets) vs centered
      640px modal tablet/desktop; header/footer pinned, list scrolls alone.
- [ ] Picker nested on all three widths; desktop search filters by typing.
- [ ] `wa.me` link: native app (mobile) vs Web/app prompt (desktop) — pre-filled.
- [ ] Desktop keyboard: Tab cycles inside dialog, Esc closes, focus returns.
- [ ] Touch targets ≥44px mobile/tablet; order grid 1→2→3 columns by width.
- [ ] Empty/error copy on all widths: no supplier, no WhatsApp number, payload
      skipped, TBC banner, offline notice, failed load + retry.

## TODO: integration point (future WhatsApp API pass)

`structured_data` maps 1:1 to WhatsApp Business Cloud API template parameters
(`po_number` → template variable, `items` → body components, `total` → footer).
When integrating: add an outbox worker consuming `SupplierMessage` rows in
`ready`, POST to Cloud API, then advance `ready→sent→delivered→read` from
webhooks (implement the inbound receiver + reply parser then). Never call the
API from the submit transaction. Also: add `whatsapp_number` et al. to the
Drift `cached_suppliers` table (+ mapper) so the directory sync carries them.
