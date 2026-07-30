FROM ghcr.io/astral-sh/uv:python3.12-bookworm AS builder

WORKDIR /app

# Install project dependencies (layer caching — rebuild only when deps change)
COPY pyproject.toml README.md ./
RUN uv sync --no-dev --no-install-project

# Copy source and install the project itself
COPY . .
RUN uv sync --no-dev

FROM ghcr.io/astral-sh/uv:python3.12-bookworm AS development

WORKDIR /app

# Install ALL dependencies (including dev: pytest, ruff, mypy, pre-commit)
COPY pyproject.toml README.md ./
RUN uv sync --no-install-project
COPY . .
RUN uv sync && chmod -R a+w /app

# Use the same user as runtime for consistency
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

FROM python:3.12-slim-bookworm AS runtime

RUN groupadd -r foodlink && useradd -r -g foodlink -d /app foodlink

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copy virtualenv + app code from builder
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app /app
RUN rm -rf /app/tests /app/.pytest_cache /app/.ruff_cache /app/uv.lock && \
    chmod -R a+r /app/keys

ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
USER foodlink

EXPOSE 8000

HEALTHCHECK --interval=15s --timeout=5s --retries=3 \
    CMD python -c "import http.client; c=http.client.HTTPConnection('localhost',8000); c.request('GET','/health'); r=c.getresponse(); exit(0) if r.status==200 else exit(1)"

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers", "--forwarded-allow-ips", "*"]
