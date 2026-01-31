# NetLyra

[简体中文](README.zh.md) | **English**

Real-time network traffic analysis with AI-powered anomaly detection.

## Stack

- **Core**: Go (gopacket, Gin, GORM)
- **AI Engine**: Python (River ML)
- **UI**: Flutter
- **Messaging**: Redpanda
- **Storage**: SQLite

## Quick Start (Docker)

```bash
docker compose up -d
```

> [!NOTE]
> Core service uses `network_mode: host` for packet capture, requires `NET_RAW` capability.

## Quick Start (Dev)

```bash
# Install dependencies
go mod tidy
cd engine && uv sync

# Start Redpanda (adjust path to your infra location)
docker compose -f /path/to/redpanda/docker-compose.yml up -d

# Run database migration
task db:sync

# Start development
task dev:all
```

## Access

- **Web HUD**: [http://localhost:8085](http://localhost:8085)
- **Redpanda Console**: [http://localhost:8080](http://localhost:8080)
- **API Health**: [http://localhost:8090/api/v1/health](http://localhost:8090/api/v1/health)

## Documentation

- [Architecture](docs/architecture.md)
- [PRD](PRODUCT_REQUIREMENTS_DOCUMENT.md)

## Technical Notes

Flutter was selected for the UI layer to leverage its unified codebase architecture, enabling potential cross-platform deployment from a single source while maintaining web-first development focus.
