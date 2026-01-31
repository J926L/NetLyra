"""Streaming anomaly detection model using River HalfSpaceTrees."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import TYPE_CHECKING

from river import anomaly

if TYPE_CHECKING:
    from engine.consumer import PacketMeta

# Model configuration
N_TREES = 25
HEIGHT = 8
WINDOW_SIZE = 250
WARMUP_PACKETS = 50
ANOMALY_THRESHOLD = 0.8


@dataclass
class FeatureSet:
    """Extracted features for anomaly scoring."""

    entropy: float
    payload_len: int
    port_ratio: float


def extract_features(pkt: PacketMeta) -> dict[str, float]:
    """Extract features from packet metadata."""
    return {
        "entropy": pkt.entropy,
        "payload_len": float(pkt.payload_len),
        "port_ratio": pkt.src_port / (pkt.dst_port + 1),
    }


@dataclass
class AnomalyDetector:
    """Streaming anomaly detector with warmup phase."""

    model: anomaly.HalfSpaceTrees = field(
        default_factory=lambda: anomaly.HalfSpaceTrees(
            n_trees=N_TREES,
            height=HEIGHT,
            window_size=WINDOW_SIZE,
        )
    )
    packet_count: int = 0
    threshold: float = ANOMALY_THRESHOLD

    def process(self, pkt: PacketMeta) -> tuple[float, bool]:
        """
        Process a packet and return (score, is_anomaly).

        During warmup phase (first 50 packets), only learns without scoring.
        """
        features = extract_features(pkt)
        self.packet_count += 1

        # Warmup phase: learn only
        if self.packet_count <= WARMUP_PACKETS:
            self.model.learn_one(features)
            return 0.0, False

        # Score then learn (prequential evaluation)
        score = self.model.score_one(features)
        self.model.learn_one(features)

        is_anomaly = score > self.threshold
        return score, is_anomaly

    @property
    def is_warmed_up(self) -> bool:
        """Check if warmup phase is complete."""
        return self.packet_count > WARMUP_PACKETS
