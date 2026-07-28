# FoodLink Inventory Service

Inventory microservice for FoodLink Africa. Handles item catalog, stock
levels, movements, adjustments, and procurement — everything that tracks
"what do we have and where".

## Architecture

This service is a **resource server** in the FoodLink ecosystem. It:

- **Verifies** JWT tokens issued by the Identity Service (it never issues
  its own tokens — only the Identity Service possesses the private key).
- **Owns its own data** in a dedicated `foodlink_inventory` Postgres database
  (it does not share Identity Service's database).
- **Publishes and subscribes** to events via a shared RabbitMQ exchange
  (configured via `RABBITMQ_URL` and `EVENTS_EXCHANGE`).

## Cross-Service JWT Verification

This service verifies tokens using the Identity Service's **public key**.
The public key must be deployed alongside this service.

### Operational Note: Public Key Distribution

In a real deployment, the public key (`keys/public.pem`) is **not** committed
as a permanent file in this repository. Instead:

1. The Identity Service's deployment pipeline exports its public key to a
   shared secret store (e.g., HashiCorp Vault, AWS Secrets Manager, or a
   Kubernetes ConfigMap).
2. This service's deployment pipeline copies that public key into
   `keys/public.pem` at deployment time (or injects it via the
   `JWT_PUBLIC_KEY_PATH` env var pointing to a mounted secret).

**Do not** rely on the checked-in `keys/public.pem` for production — it
exists here only for local development convenience. A deployment-time copy
step ensures that key rotation in the Identity Service propagates to all
resource servers without a source-control PR.

## RabbitMQ Topology Notes

The shared RabbitMQ instance may run:

- **As part of this compose stack** — add a `rabbitmq` service to
  `docker-compose.yml` and wire `RABBITMQ_URL` to it.
- **As a separate shared stack** — point `RABBITMQ_URL` at the shared
  instance's host and port.

The choice depends on whether RabbitMQ is treated as platform infrastructure
(shared stack) or per-service infrastructure (in-stack). The compose file
in this repo currently assumes it is shared infrastructure and does not
include a RabbitMQ container — this is the recommended default.

## Local Development

```bash
cp .env.example .env
# Ensure keys/public.pem exists (copied from identity-service/keys/public.pem)
# Requires Python 3.12+ and uv installed

uv sync
uv run alembic upgrade head
uv run uvicorn app.main:app --reload
```

## Tests

Run the full suite (98 tests covering CRUD, auth, schemas, movement engine,
and operation endpoints) with a single command:

```bash
docker compose run --rm api-dev uv run pytest -v tests/
```

Run a specific subset:

```bash
# Service-layer tests (movement engine)
docker compose run --rm api-dev uv run pytest -v tests/services/

# API integration tests
docker compose run --rm api-dev uv run pytest -v tests/api/
```

## Docker Compose

```bash
docker compose up --build
```

This starts the API on port 8100 and a dedicated Postgres instance on port 5433.