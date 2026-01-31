package producer

import (
	"context"
	"fmt"
	"time"

	"encoding/json"

	"github.com/segmentio/kafka-go"

	"netlyra/internal/models"
)

// Producer Redpanda/Kafka 消息生产者
type Producer struct {
	writer *kafka.Writer
	topic  string
}

// NewProducer 创建新的生产者
func NewProducer(brokers []string, topic string) *Producer {
	writer := &kafka.Writer{
		Addr:         kafka.TCP(brokers...),
		Topic:        topic,
		Balancer:     &kafka.LeastBytes{},
		BatchSize:    100,
		BatchTimeout: 10 * time.Millisecond,
		Async:        true, // 异步写入，提高吞吐
	}

	return &Producer{
		writer: writer,
		topic:  topic,
	}
}

// Send 发送数据包元数据
func (p *Producer) Send(ctx context.Context, meta *models.PacketMeta) error {
	data, err := json.Marshal(meta)
	if err != nil {
		return fmt.Errorf("marshal packet: %w", err)
	}

	// 使用 5-tuple 作为 key，保证相同连接的包发到同一分区
	key := fmt.Sprintf("%s:%d-%s:%d-%s",
		meta.SrcIP, meta.SrcPort,
		meta.DstIP, meta.DstPort,
		meta.Protocol,
	)

	return p.writer.WriteMessages(ctx, kafka.Message{
		Key:   []byte(key),
		Value: data,
	})
}

// SendBatch 批量发送
func (p *Producer) SendBatch(ctx context.Context, metas []*models.PacketMeta) error {
	messages := make([]kafka.Message, 0, len(metas))

	for _, meta := range metas {
		data, err := json.Marshal(meta)
		if err != nil {
			continue // 跳过序列化失败的
		}

		key := fmt.Sprintf("%s:%d-%s:%d-%s",
			meta.SrcIP, meta.SrcPort,
			meta.DstIP, meta.DstPort,
			meta.Protocol,
		)

		messages = append(messages, kafka.Message{
			Key:   []byte(key),
			Value: data,
		})
	}

	if len(messages) == 0 {
		return nil
	}

	return p.writer.WriteMessages(ctx, messages...)
}

// Close 关闭生产者
func (p *Producer) Close() error {
	if p.writer != nil {
		return p.writer.Close()
	}
	return nil
}
