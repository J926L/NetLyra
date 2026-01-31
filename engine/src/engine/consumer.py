"""Kafka consumer for netlyra.packets topic."""

from __future__ import annotations

import signal
from dataclasses import dataclass
from typing import TYPE_CHECKING

import orjson
from kafka import KafkaConsumer

if TYPE_CHECKING:
    from collections.abc import Iterator

# Broker configuration
BROKER = "localhost:19092"
TOPIC = "netlyra.packets"
GROUP_ID = "netlyra-engine-consumer"


@dataclass(slots=True, frozen=True)
class PacketMeta:
    """Packet metadata from Go producer."""

    ts: str
    src_ip: str
    dst_ip: str
    src_port: int
    dst_port: int
    proto: str
    payload_len: int
    entropy: float
    tcp_flags: str | None = None

    @classmethod
    def from_json(cls, data: bytes) -> PacketMeta:
        """Deserialize from JSON bytes."""
        obj = orjson.loads(data)
        return cls(
            ts=obj["ts"],
            src_ip=obj["src_ip"],
            dst_ip=obj["dst_ip"],
            src_port=obj["src_port"],
            dst_port=obj["dst_port"],
            proto=obj["proto"],
            payload_len=obj["payload_len"],
            entropy=obj["entropy"],
            tcp_flags=obj.get("tcp_flags"),
        )


class PacketConsumer:
    """Kafka consumer for packet metadata stream."""

    def __init__(self, broker: str = BROKER, topic: str = TOPIC) -> None:
        self._consumer = KafkaConsumer(
            topic,
            bootstrap_servers=broker,
            group_id=GROUP_ID,
            auto_offset_reset="latest",
            enable_auto_commit=True,
            value_deserializer=lambda x: x,  # Raw bytes
        )
        self._running = True

        # Graceful shutdown
        signal.signal(signal.SIGINT, self._shutdown)
        signal.signal(signal.SIGTERM, self._shutdown)

    def _shutdown(self, _signum: int, _frame: object) -> None:
        """Handle shutdown signals."""
        print("\n[Consumer] Shutting down...")
        self._running = False

    def stream(self) -> Iterator[PacketMeta]:
        """Yield PacketMeta objects from Kafka stream."""
        print(f"[Consumer] Listening to {TOPIC}...")
        try:
            for msg in self._consumer:
                if not self._running:
                    break
                try:
                    yield PacketMeta.from_json(msg.value)
                except (orjson.JSONDecodeError, KeyError) as e:
                    print(f"[Consumer] Parse error: {e}")
                    continue
        finally:
            self._consumer.close()
            print("[Consumer] Closed.")

    def close(self) -> None:
        """Close consumer connection."""
        self._running = False
        self._consumer.close()


if __name__ == "__main__":
    # Test consumer standalone
    consumer = PacketConsumer()
    for pkt in consumer.stream():
        print(f"[Packet] {pkt.src_ip}:{pkt.src_port} -> {pkt.dst_ip}:{pkt.dst_port}")
