# ============ Go Core ============
FROM golang:1.25-bookworm AS go-builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY cmd/ cmd/
COPY internal/ internal/
RUN CGO_ENABLED=1 go build -o /netlyra ./cmd/netlyra

# --- Python Engine Stage ---
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS engine

WORKDIR /app/engine
COPY engine/pyproject.toml engine/uv.lock ./
# Sync dependencies (cached)
RUN uv sync --frozen --no-install-project

# Copy source
COPY engine/ .
# Install project
RUN uv sync --frozen

CMD ["uv", "run", "python", "-m", "engine.main"]

# ============ Final Runtime ============
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    libpcap0.8 \
    && rm -rf /var/lib/apt/lists/*

CMD ["/start.sh"]
