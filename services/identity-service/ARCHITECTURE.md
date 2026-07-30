# Architecture

## Folder structure

```
app/
├── main.py                 # FastAPI app factory, lifespan, router registration
├── core/                   # Cross-cutting infrastructure
│   ├── config.py           # pydantic-settings (env → typed config)
│   ├── database.py         # async engine, session factory, get_db dependency
│   ├── logging.py          # structlog configuration
│   ├── security.py         # placeholder — JWT, hashing, rate-limit helpers
│   └── telemetry.py        # placeholder — OpenTelemetry (commented until needed)
├── models/                 # SQLModel table=True — DB table definitions
│   ├── base.py             # UUIDMixin, TimestampMixin
│   └── ... (User, Session, OTPCode, etc. — added later)
├── schemas/                # SQLModel table=False / Pydantic — API shapes
│   ├── health.py           # Health / Readiness response schemas
│   └── ... (auth request/response DTOs — added later)
├── routers/                # FastAPI APIRouter modules (thin — parse, delegate)
│   ├── health.py           # GET /health, GET /health/ready
│   └── ... (auth, otp, sessions, staff — added later)
├── services/               # Business logic layer
│   └── ... (AuthService, OTPService, etc. — added later)
└── repositories/           # Data access layer (one class per model)
    └── ... (UserRepository, SessionRepository, etc. — added later)

migrations/                 # Alembic (env.py wired to Settings + SQLModel.metadata)
tests/
├── conftest.py             # async client fixture, DB lifecycle (TBD)
├── unit/                   # Pure logic tests, no DB
└── integration/            # End-to-end tests with DB + Redis
```

## Layered request flow

```
HTTP → Router → Service → Repository → Database
         ↓          ↑
      Schema       Model
    (validate)   (transform)
```

- **Routers**: Parse/validate request, call service, serialize response.
  No business logic here.
- **Services**: Orchestrate business rules, compose multiple repo calls,
  raise domain exceptions.
- **Repositories**: Data access — CRUD on a single SQLModel table, accept
  AsyncSession, return model instances.
- **Models** (`table=True`): SQLAlchemy columns + Pydantic validation.
- **Schemas** (`table=False`): API-only shapes, decoupled from DB internals.

## Key decisions

### SQLModel over plain SQLAlchemy + separate Pydantic

**Why**: One class can serve as both DB model and API schema when the shapes
coincide, eliminating redundancy. When they diverge (which is common for
responses that shouldn't leak `updated_at`, `deleted_at`, etc.), use a
separate `table=False` schema. This strikes a pragmatic balance — DRY where
safe, explicit where needed.

**Known friction**: SQLModel's metaclass adds complexity in mypy strict mode.
Field types sometimes need `# type: ignore[arg-type]`. Pinned to SQLModel
>=0.0.22 which improves the async story.

### Async over sync

**Why**: FastAPI is async-native. All 4 Flutter apps will make concurrent
requests; blocking the event loop on DB queries would waste throughput.
Asyncpg (the async Postgres driver) also performs better under connection
pooling.

**Cost**: Slightly more complex test setup (async fixtures, event loop
management). Worth it for a service that will be the request bottleneck.

### RS256 JWTs (planned)

**Why**: Asymmetric signing lets Flutter apps and the Next.js dashboard
verify tokens without holding the private key. The auth service alone signs;
every service verifies with the public key.

### Redis for session store (even though nothing uses it yet)

**Why**: JWT refresh tokens, rate-limit counters, and OTP code TTL all
benefit from Redis' TTL-based expiry. Adding Redis at the scaffold stage
gets it into Docker Compose and the health check from day one, avoiding a
"oh, we need Redis now" scramble later.

### uv over Poetry

**Why**: 10–100x faster dependency resolution, from the same team as ruff.
`uv sync` is near-instant, which matters in CI. Poetry is more mature but
the speed difference is decisive for developer experience.

### structlog over loguru

**Why**: Native integration with stdlib logging, built-in JSON output for
production, and first-class support for context variables (request IDs,
trace IDs). Loguru is simpler for scripts but harder to configure for
proper JSON logging in containers.
