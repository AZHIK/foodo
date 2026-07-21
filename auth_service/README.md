# FoodLink Auth Service

Single sign-on identity / auth microservice for the FoodLink Africa platform.
Serves all 4 Flutter apps + the Next.js dashboard with token-based authentication,
OTP flows, session management, and role-based access control.

## Quick start

```bash
# 1. Copy environment config
cp .env.example .env

# 2. Generate JWT signing keys (one-time)
uv run python scripts/generate_keys.py

# 3. Start everything (Postgres + Redis + API)
docker compose up --build

# 4. Verify health
curl http://localhost:8000/health
curl http://localhost:8000/health/ready

# 5. (Optional) pgAdmin + dev tools at http://localhost:5050
docker compose --profile dev up
```

## Run migrations

```bash
# Get a shell inside the running API container
docker compose exec api alembic upgrade head

# To create a new migration after adding a model
docker compose exec api alembic revision --autogenerate -m "description"
```

## Run tests & lint

The `api` service runs a production-minimal image without dev tooling.
For tests, linting, and type-checking, use the `api-dev` service:

```bash
# Start the dev service (one-time, --profile dev flag)
docker compose --profile dev up -d

# Get a shell with all tools available
docker compose exec api-dev bash
uv run pytest -v
uv run ruff check app tests
uv run ruff format --check app tests
uv run mypy app
```

To run directly on the host (if you have the dependencies installed):

```bash
uv run pytest
uv run ruff check app tests
uv run ruff format --check app tests
uv run mypy app
```

## OpenAPI docs

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### Client generation

Once endpoints are stable, generate typed clients:

- **Dart/Flutter**: `dart run build_runner build` with `openapi_generator` or use
  [openapi-generator](https://openapi-generator.tech) with the `dart` target.
- **TypeScript/Next.js**: Use `openapi-typescript` to generate types + `openapi-fetch`
  for a thin client.

These tools consume `GET http://localhost:8000/openapi.json`.

## What's NOT built yet

This scaffold is project structure, tooling, and Docker only. The following
feature work still needs implementation:

- [ ] OTP send/verify endpoints (Twilio / Africa's Talking / Termii)
- [ ] Email/password registration and login
- [x] JWT signing and verification (RS256)
- [x] Password hashing (bcrypt)
- [x] Refresh token primitives
- [x] OTP code hashing
- [ ] Access + refresh token flow
- [ ] Session management (active sessions, force logout)
- [ ] Staff PIN login
- [ ] Role-based access control (RBAC) endpoints
- [ ] Rate limiting
- [ ] OpenTelemetry distributed tracing
- [ ] CI/CD pipeline (GitHub Actions / GitLab CI)
- [ ] Production Docker secrets (JWT keys, DB passwords)

## Tech stack

| Layer | Choice | Reason |
|-------|--------|--------|
| Framework | FastAPI | Async-native, automatic OpenAPI, Pydantic integration |
| ORM | SQLModel | SQLAlchemy 2.0 + Pydantic in one model class |
| DB | PostgreSQL 16 | Mature, JSONB for flexible profile data |
| Cache | Redis 7 | Session store, rate-limit counters, OTP TTL |
| Migrations | Alembic | Standard for SQLAlchemy-based projects |
| Package mgr | uv | Fastest Python resolver, from Astral (ruff too) |
| Linting | ruff | 100x faster than flake8, built-in formatter |
| Types | mypy | Strict mode, best-in-class for gradual typing |
| Logging | structlog | JSON structured logging for production |

## Architecture

See [ARCHITECTURE.md](./ARCHITECTURE.md) for folder layout, layer responsibilities,
and key design decisions.
