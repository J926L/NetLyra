"""NetLyra Engine - Main entry point."""

from __future__ import annotations

import sys

from engine.consumer import PacketConsumer
from engine.model import AnomalyDetector, extract_features
from engine.producer import Alert, AlertProducer


def main() -> int:
    """Run the anomaly detection pipeline."""
    print("[Engine] Starting NetLyra AI Engine...")

    consumer = PacketConsumer()
    producer = AlertProducer()
    detector = AnomalyDetector()

    try:
        for pkt in consumer.stream():
            score, is_anomaly = detector.process(pkt)

            # Log progress during warmup
            if not detector.is_warmed_up:
                print(f"[Warmup] {detector.packet_count}/50 packets processed")
                continue

            # Send alert if anomaly detected
            if is_anomaly:
                features = extract_features(pkt)
                alert = Alert.from_packet(pkt, score, features)
                producer.send(alert)

    except KeyboardInterrupt:
        print("\n[Engine] Interrupted by user.")
    finally:
        consumer.close()
        producer.close()
        print("[Engine] Shutdown complete.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
