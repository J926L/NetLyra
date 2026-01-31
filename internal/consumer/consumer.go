package consumer

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/segmentio/kafka-go"
	"gorm.io/gorm"

	"netlyra/internal/api"
	"netlyra/internal/models"
)

// AlertConsumer consumes alerts from Kafka and broadcasts to WebSocket
type AlertConsumer struct {
	reader *kafka.Reader
	db     *gorm.DB
	hub    *api.Hub
}

// alertPayload matches Python engine producer.Alert structure
type alertPayload struct {
	Timestamp string             `json:"ts"`
	SrcIP     string             `json:"src_ip"`
	DstIP     string             `json:"dst_ip"`
	SrcPort   uint16             `json:"src_port"`
	DstPort   uint16             `json:"dst_port"`
	Protocol  string             `json:"proto"`
	Score     float64            `json:"score"`
	Features  map[string]float64 `json:"features"`
}

// NewAlertConsumer creates a new alert consumer
func NewAlertConsumer(db *gorm.DB, hub *api.Hub, brokers []string, topic string) *AlertConsumer {
	reader := kafka.NewReader(kafka.ReaderConfig{
		Brokers:        brokers,
		Topic:          topic,
		GroupID:        "netlyra-core",
		MinBytes:       1,
		MaxBytes:       10e6,
		CommitInterval: time.Second,
	})
	return &AlertConsumer{
		reader: reader,
		db:     db,
		hub:    hub,
	}
}

// Run starts consuming alerts
func (c *AlertConsumer) Run(ctx context.Context) error {
	log.Printf("[AlertConsumer] Subscribing to topic: %s", c.reader.Config().Topic)

	for {
		select {
		case <-ctx.Done():
			return c.reader.Close()
		default:
		}

		msg, err := c.reader.FetchMessage(ctx)
		if err != nil {
			if ctx.Err() != nil {
				return nil // Context cancelled
			}
			log.Printf("[AlertConsumer] fetch error: %v", err)
			continue
		}

		if err := c.processMessage(msg); err != nil {
			log.Printf("[AlertConsumer] process error: %v", err)
		}

		if err := c.reader.CommitMessages(ctx, msg); err != nil {
			log.Printf("[AlertConsumer] commit error: %v", err)
		}
	}
}

func (c *AlertConsumer) processMessage(msg kafka.Message) error {
	var payload alertPayload
	if err := json.Unmarshal(msg.Value, &payload); err != nil {
		return fmt.Errorf("unmarshal alert: %w", err)
	}

	// Parse timestamp
	ts, err := time.Parse(time.RFC3339, payload.Timestamp)
	if err != nil {
		ts = time.Now() // Fallback
	}

	// Serialize features to JSON
	featuresJSON, _ := json.Marshal(payload.Features)

	// Create alert model
	alert := models.Alert{
		Timestamp: ts,
		SrcIP:     payload.SrcIP,
		DstIP:     payload.DstIP,
		SrcPort:   payload.SrcPort,
		DstPort:   payload.DstPort,
		Protocol:  payload.Protocol,
		Score:     payload.Score,
		Features:  string(featuresJSON),
	}

	// Save to database
	if err := c.db.Create(&alert).Error; err != nil {
		return fmt.Errorf("save alert: %w", err)
	}

	// Broadcast via WebSocket
	c.hub.Broadcast("alert", map[string]interface{}{
		"id":       alert.ID,
		"ts":       alert.Timestamp.UnixMilli(),
		"src_ip":   alert.SrcIP,
		"dst_ip":   alert.DstIP,
		"src_port": alert.SrcPort,
		"dst_port": alert.DstPort,
		"protocol": alert.Protocol,
		"score":    alert.Score,
	})

	log.Printf("[Alert] Score=%.3f %s:%d → %s:%d",
		alert.Score, alert.SrcIP, alert.SrcPort, alert.DstIP, alert.DstPort)

	return nil
}

// Close closes the consumer
func (c *AlertConsumer) Close() error {
	return c.reader.Close()
}
