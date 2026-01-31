"""Kafka producer for netlyra.alerts topic."""

from __future__ import annotations

from dataclasses import asdict, dataclass
from datetime import UTC, datetime
from typing import TYPE_CHECKING

import orjson
from kafka import KafkaProducer

if TYPE_CHECKING:
    from engine.consumer import PacketMeta

# Broker configuration
BROKER = "localhost:19092"
TOPIC = "netlyra.alerts"


@dataclass(slots=True)
class Alert:
    """Alert payload matching Go GORM Alert model."""

    ts: str
    src_ip: str
    dst_ip: str
    src_port: int
    dst_port: int
    proto: str
    score: float
    features: dict[str, float]

    @classmethod
    def from_packet(
        cls,
        pkt: PacketMeta,
        score: float,
        features: dict[str, float],
    ) -> Alert:
        """Create alert from packet metadata and scoring results."""
        return cls(
            ts=datetime.now(UTC).isoformat(),
            src_ip=pkt.src_ip,
            dst_ip=pkt.dst_ip,
            src_port=pkt.src_port,
            dst_port=pkt.dst_port,
            proto=pkt.proto,
            score=score,
            features=features,
        )

    def to_json(self) -> bytes:
        """Serialize to JSON bytes."""
        return orjson.dumps(asdict(self))


class AlertProducer:
    """Kafka producer for anomaly alerts."""

    def __init__(self, broker: str = BROKER, topic: str = TOPIC) -> None:
        self._producer = KafkaProducer(
            bootstrap_servers=broker,
            value_serializer=lambda x: x,  # Raw bytes
        )
        self._topic = topic

    def send(self, alert: Alert) -> None:
        """Send alert to Kafka topic."""
        key = f"{alert.src_ip}:{alert.src_port}-{alert.dst_ip}:{alert.dst_port}"
        self._producer.send(
            self._topic,
            key=key.encode(),
            value=alert.to_json(),
        )
        print(f"[Alert] Score={alert.score:.3f} {alert.src_ip} -> {alert.dst_ip}")

    def close(self) -> None:
        """Flush and close producer."""
        self._producer.flush()
        self._producer.close()
        print("[Producer] Closed.")
