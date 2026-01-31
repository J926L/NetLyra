# NetLyra Project State

## Overview

NetLyra is a real-time network traffic analysis system with AI anomaly detection.
Current State: Alert broadcast integration complete, WASM POC built.

## Accomplishments

### Foundation

- **Architecture**: Defined data flow (NIC -> Go -> Redpanda -> Python -> SQLite -> Flutter).
- **Environment**: Taskfile, uv (Python), Go 1.25.6 sync.
- **Database**: SQLite with GORM (Alerts, Connections tables) migrated.
- **Infra**: Redpanda (External container at `/home/j/infra/redpanda/`).

### Go Core (Engine)

- **Capture**: `internal/capture` using `gopacket` (L2-L4 decoding + Entropy).
- **Producer**: `internal/producer` for Redpanda (Async batching).
- **Consumer**: `internal/consumer` - Kafka consumer for `netlyra.alerts` (broadcasts to WebSocket).
- **API**: `internal/api` using Gin (REST + WebSocket Hub).
- **WASM**: `wasm/` - Pure Go subset (entropy, packet parsing), 3.2MB binary.
- **Testing**: Bruno scripts in `bruno/` for API verification.
- **Port Mapping**: `:8090` (API + WebSocket at `/ws`).

### Python AI Engine

- **Consumer**: `engine/src/engine/consumer.py` - Kafka consumer for `netlyra.packets`.
- **Model**: `engine/src/engine/model.py` - River HalfSpaceTrees (25 trees, 50-packet warmup).
- **Producer**: `engine/src/engine/producer.py` - Alert producer for `netlyra.alerts`.
- **Entry**: `engine/src/engine/main.py` - Pipeline orchestration.
- **Verification**: Ruff lint + Pyright type check passed.

### Flutter UI (In Progress)

- **Scaffold**: `ui/` (Flutter).
- Verified Google Fonts integration (Orbitron, Noto Sans SC, Share Tech Mono).
- **Widgets**: GlowText, BentoCard, StatTile.
- **Services**: WebSocket service with auto-reconnect.
- **Pages**: Dashboard with Bento grid layout.
- **Build**: Linux debug build successful (`build/linux/x64/debug/bundle/netlyra_ui`).

## Tech Stack

- **Go**: 1.25.6 (Gin, GORM, gopacket, segmentio/kafka-go).
- **Python**: 3.12 (uv, river, kafka-python-ng, orjson).
- **Flutter**: fvm (web_socket_channel, fl_chart, provider).
- **Messaging**: Redpanda (External).
- **Storage**: SQLite.

## Future Plans

### Flutter UI Remaining

- [x] Complete WebSocket-UI data wiring.
- [x] Implement Cyberpunk HUD (Scanlines, Glitch, Glow).
- [x] Integrate real-time charting.

### System Integration

- [x] Verified end-to-end alert latency.
- [x] Optimized Taskfile for one-command dev launch.

## Critical Notes

- Packet capture requires root: `sudo ./bin/netlyra -iface eth0`.
- Kafka brokers at `localhost:19092`.
- `memory/STATE.md` is the source of truth for handoff.
