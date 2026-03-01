# NetLyra Project State

## Overview

NetLyra is a real-time network traffic analysis system with AI anomaly detection.
Current State: Alert broadcast integration complete, WASM- **Core Goals**: Network capture, Machine Learning analysis, and RESTful APIs.

## Accomplishments

### Foundation

- **Architecture**: Defined data flow (NIC -> Go -> Redpanda -> Python -> SQLite).
- **Environment**: Taskfile, uv (Python), Go 1.25.6 sync.
- **Database**: SQLite with GORM (Alerts, Connections tables) migrated.
- **Infra**: Redpanda (External container at `/home/j/infra/redpanda/`).

### Go Core (Engine)

- **Capture**: `internal/capture` using `gopacket` (L2-L4 decoding + Entropy).
- **Producer**: `internal/producer` for Redpanda (Async batching).
- **Consumer**: `internal/consumer` - Kafka consumer for `netlyra.alerts` (saves to DB).
- **API**: `internal/api` using Gin (REST).
- **WASM**: `wasm/` - Pure Go subset (entropy, packet parsing), 3.2MB binary.
- **Testing**: Go native `httptest` for API verification.
- **Database**: GORM with SQLite (`data/netlyra.db`).
- **Build**: Taskfile for automation.
- **Port Mapping**: `:8090` (API).

### Python AI Engine

- **Consumer**: `engine/src/engine/consumer.py` - Kafka consumer for `netlyra.packets`.
- **Model**: `engine/src/engine/model.py` - River HalfSpaceTrees (25 trees, 50-packet warmup).
- **Producer**: `engine/src/engine/producer.py` - Alert producer for `netlyra.alerts`.
- **Entry**: `engine/src/engine/main.py` - Pipeline orchestration.
- **Verification**: Ruff lint + Pyright type check passed.

## Tech Stack

- **Go**: 1.25.6 (Gin, GORM, gopacket, segmentio/kafka-go).
- **Python**: 3.12 (uv, river, kafka-python-ng, orjson).
- **Messaging**: Redpanda (External).
- **Storage**: SQLite.

## Future Plans

### Deployment

- [ ] Implement `docker-compose` orchestration.

### System Integration

- [x] Verified end-to-end alert latency.
- [x] Optimized Taskfile for one-command dev launch.

## Critical Notes

- Packet capture requires root: `sudo ./bin/netlyra -iface eth0`.
- Kafka brokers at `localhost:19092`.
- `memory/STATE.md` is the source of truth for handoff.
