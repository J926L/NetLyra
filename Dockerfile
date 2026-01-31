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

# ============ Flutter Web ============
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-builder

WORKDIR /app
COPY ui/ .
RUN flutter pub get && flutter build web --release

# ============ NGINX + Go Runtime ============
FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpcap0.8 nginx ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy Go binary
COPY --from=go-builder /netlyra /usr/local/bin/netlyra
RUN setcap cap_net_raw+ep /usr/local/bin/netlyra || true

# Copy Flutter Web
COPY --from=flutter-builder /app/build/web /var/www/html

# NGINX config
RUN echo 'server { \
    listen 8085; \
    root /var/www/html; \
    location / { try_files $uri $uri/ /index.html; } \
    }' > /etc/nginx/sites-available/default

EXPOSE 8085 8090 8091

# Start script
COPY <<EOF /start.sh
#!/bin/bash
nginx
exec /usr/local/bin/netlyra --iface eth0
EOF
RUN chmod +x /start.sh

CMD ["/start.sh"]
