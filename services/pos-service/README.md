# FoodLink POS Service

Point-of-sale microservice for FoodLink Africa. Manages sales transactions,
line items, payments, receipts, and local tax configuration.

- **Database**: dedicated `foodlink_pos` PostgreSQL instance (not shared).
- **Auth**: verifies RS256 JWTs issued by Identity Service (never issues tokens).
- **Events**: publishes sale lifecycle events (`sale.completed`, `sale.voided`,
  `sale.refunded`) via a shared RabbitMQ exchange.
- **Port**: `8200`

---

## Quick Start

```bash
cp .env.example .env
cp ../identity-service/keys/public.pem keys/
uv sync
uv run alembic upgrade head
uv run uvicorn app.main:app --reload
```

---

## Available Endpoints

| Method | Path | Permission | Purpose |
|--------|------|------------|---------|
| `GET` | `/health` | none | Liveness probe |
| `POST` | `/businesses/{business_id}/sales/sync` | `pos.write` | Batch-sync offline sales |
| `GET` | `/businesses/{business_id}/sales` | `pos.view` | List sales (paginated, filterable) |
| `GET` | `/businesses/{business_id}/sales/summary` | `pos.view` | Aggregate summary (revenue, voided, refunded, payment-method breakdown) |
| `GET` | `/businesses/{business_id}/sales/{sale_id}` | `pos.view` | Read single sale by server ID |
| `GET` | `/businesses/{business_id}/sales/by-client-id/{client_sale_id}` | `pos.view` | Read single sale by client idempotency key |
| `POST` | `/businesses/{business_id}/sales/{sale_id}/void-or-refund` | `pos.refund` | Void or refund a completed sale |

All `pos.*` endpoints enforce **business-context binding**: the URL path's
`business_id` must match the JWT's `active_business_id` claim.

---

## Design Decisions (with in-file documentation anchors)

Every non-trivial design choice is documented at the point of implementation.
Key locations:

| Decision | File & Line |
|----------|-------------|
| Cross-service reference columns (no FK constraints) | `app/models/pos.py:4-18` |
| Why no `processed_sync_events` table | `app/models/pos.py:20-28` |
| Sale state machine (terminal states only) | `app/models/pos.py:31-38` |
| Pre-voided / pre-refunded sale on first sync | `app/schemas/sales.py:3-19` |
| Partial-success batch design (not all-or-nothing) | `app/schemas/sales.py:14-20` |
| Business-context binding (Gap 1 fix) | `app/deps/auth.py:126-148` |
| Event-publish stub (RabbitMQ deferred) | `app/core/events.py:1-4` |
| PermissionCode duplication / shared-package extraction | `app/core/permission_codes.py:1-13` |
| Per-sale independent transactions in batch sync | `app/services/sale_service.py:69-75` |

---

## KNOWN GAPS

### 1. Inventory Service does not yet consume `sale.voided` / `sale.refunded`

POS Service correctly publishes `sale.voided` and `sale.refunded` events
with full line-item payloads (`void_or_refund_sale()` at
`sale_service.py:284-298`). However, Inventory Service has **no handler**
for these events — stock is **not reversed** when a sale is voided or
refunded.

- POS-side test: `test_KNOWN_GAP_inventory_does_not_yet_reverse_stock_on_void`
  in `tests/services/test_sale_service.py:928`.
- Fix target: add `handle_sale_voided` / `handle_sale_refunded` in
  Inventory Service's `app/services/event_handlers.py`.

### 2. Shared-package extraction (prep for Service #4)

`security.py`, `deps/auth.py`, and `PermissionCode` (`permission_codes.py`)
are duplicated across POS Service and Identity Service. Before starting
Service #4 (Procurement or whichever comes next), extract these into a
**shared Python package** that both services import.

- See the TODO-FIXME header in `app/core/permission_codes.py:12`.

---

## Cross-Service JWT Verification

POS Service verifies tokens using Identity Service's **public key**
(`keys/public.pem`). It never possesses a private key.

**Operational note**: in production, the public key is deployed via a
secret store (Vault, K8s ConfigMap, etc.) — do not rely on the checked-in
key for production. Key rotation in Identity Service must propagate to all
resource servers.

---

## RabbitMQ Topology

The compose file in this repo does **not** include a RabbitMQ container
(RabbitMQ is treated as shared platform infrastructure). Set
`RABBITMQ_URL` and `EVENTS_EXCHANGE` in `.env` to point to the shared
instance.

Currently all event publishing is a **stub** that logs only
(`app/core/events.py:13`). Real RabbitMQ wiring is deferred to a later
stage.

---

## Local Development

```bash
cp .env.example .env
cp ../identity-service/keys/public.pem keys/   # required for JWT verification
uv sync
uv run alembic upgrade head
uv run uvicorn app.main:app --reload
```

---

## Docker Compose

```bash
docker compose up --build
```

Starts the API on port 8200 and a dedicated Postgres on port 5435.

A dev profile is also available (hot-reload via volume mount):

```bash
docker compose --profile dev up -d
docker compose exec api-dev tail -f /dev/null  # attach your editor
```

---

## Tests

Requires a running Postgres (either via Docker Compose or a local instance
with the `DB_URL` from `.env.example`).

```bash
# Via Docker Compose dev profile
docker compose --profile dev up -d
docker compose exec api-dev uv run pytest -v tests/

# Or directly (if Postgres is running on localhost:5432)
uv run pytest -v tests/
```

Full suite (113+ tests):

```bash
uv run pytest -v tests/ --tb=short
```
