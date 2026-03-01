"""NetLyra Engine - Streaming Anomaly Detection.

This package provides real-time anomaly detection for network traffic
using River ML's HalfSpaceTrees algorithm.

Modules:
    consumer: Kafka consumer for packet metadata
    model: Anomaly detection with feature extraction
    producer: Kafka producer for alerts
    main: Pipeline entry point
"""

from engine.consumer import PacketConsumer, PacketMeta
from engine.model import AnomalyDetector
from engine.producer import Alert, AlertProducer

__all__ = [
    "AnomalyDetector",
    "Alert",
    "AlertProducer",
    "PacketConsumer",
    "PacketMeta",
]
