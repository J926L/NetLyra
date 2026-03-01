package consumer

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/segmentio/kafka-go"
	"gorm.io/gorm"

	"netlyra/internal/models"
)

// AlertConsumer consumes alerts from Kafka and queues them for batch insert
type AlertConsumer struct {
	reader   *kafka.Reader
	db       *gorm.DB
	batch    []*models.Alert
	batchCmd chan *models.Alert
	done     chan struct{}
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
func NewAlertConsumer(db *gorm.DB, brokers []string, topic string) *AlertConsumer {
	reader := kafka.NewReader(kafka.ReaderConfig{
		Brokers:        brokers,
		Topic:          topic,
		GroupID:        "netlyra-core",
		MinBytes:       1,
		MaxBytes:       10e6,
		CommitInterval: time.Second,
	})
	return &AlertConsumer{
		reader:   reader,
		db:       db,
		batch:    make([]*models.Alert, 0, 100),
		batchCmd: make(chan *models.Alert, 1000),
		done:     make(chan struct{}),
	}
}

// Run starts consuming alerts
func (c *AlertConsumer) Run(ctx context.Context) error {
	log.Printf("[AlertConsumer] Subscribing to topic: %s", c.reader.Config().Topic)

	// Start batch writer routine
	go c.batchWriter(ctx)

	for {
		select {
		case <-ctx.Done():
			close(c.batchCmd) // signals batchWriter to flush and exit
			<-c.done          // wait for flush completion
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

	// Queue to batch worker instead of saving directly
	c.batchCmd <- &alert

	log.Printf("[Alert] Score=%.3f %s:%d → %s:%d",
		alert.Score, alert.SrcIP, alert.SrcPort, alert.DstIP, alert.DstPort)

	return nil
}

func (c *AlertConsumer) batchWriter(ctx context.Context) {
	defer close(c.done)

	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	flush := func() {
		if len(c.batch) == 0 {
			return
		}

		if err := c.db.CreateInBatches(c.batch, 100).Error; err != nil {
			log.Printf("[AlertConsumer] Batch insert error: %v", err)
		} else {
			log.Printf("[AlertConsumer] Flushed %d alerts to DB", len(c.batch))
		}

		// Reset batch
		c.batch = c.batch[:0]
	}

	for {
		select {
		case <-ticker.C:
			flush()
		case alert, ok := <-c.batchCmd:
			if !ok {
				// Channel closed, final flush
				flush()
				return
			}
			c.batch = append(c.batch, alert)
			if len(c.batch) >= 100 {
				flush()
			}
		}
	}
}

// Close closes the consumer
func (c *AlertConsumer) Close() error {
	return c.reader.Close()
}
