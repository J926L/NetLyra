package models

import (
	"time"
)

// Alert 异常检测结果 - AI Engine 生成
type Alert struct {
	ID        uint      `gorm:"primaryKey"`
	Timestamp time.Time `gorm:"index"` // 事件发生时间
	SrcIP     string    `gorm:"size:45;index"`
	DstIP     string    `gorm:"size:45;index"`
	SrcPort   uint16
	DstPort   uint16
	Protocol  string  `gorm:"size:10"` // TCP/UDP/ICMP
	Score     float64 // 异常分数 (0-1), >0.8 触发告警
	Features  string  `gorm:"type:json"` // 特征快照 JSON
	CreatedAt time.Time
}

// Connection 连接追踪 - 5元组聚合统计
type Connection struct {
	ID          uint      `gorm:"primaryKey"`
	FiveTuple   string    `gorm:"uniqueIndex;size:128"` // src:port-dst:port-proto
	PacketCount uint64
	ByteCount   uint64
	FirstSeen   time.Time
	LastSeen    time.Time `gorm:"index"`
}

// PacketMeta 数据包元数据 - 用于 Redpanda 消息
type PacketMeta struct {
	Timestamp   time.Time `json:"ts"`
	SrcIP       string    `json:"src_ip"`
	DstIP       string    `json:"dst_ip"`
	SrcPort     uint16    `json:"src_port"`
	DstPort     uint16    `json:"dst_port"`
	Protocol    string    `json:"proto"`
	PayloadLen  int       `json:"payload_len"`
	TCPFlags    string    `json:"tcp_flags,omitempty"`
	Entropy     float64   `json:"entropy"` // 载荷熵值
}
