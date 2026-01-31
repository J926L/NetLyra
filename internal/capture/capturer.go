package capture

import (
	"context"
	"fmt"
	"log"
	"math"
	"sync"
	"time"

	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"
	"github.com/google/gopacket/pcap"

	"netlyra/internal/models"
)

// Capturer 网络包捕获器
type Capturer struct {
	iface      string
	snapLen    int32
	promisc    bool
	timeout    time.Duration
	handle     *pcap.Handle
	packetChan chan *models.PacketMeta
	mu         sync.RWMutex
	running    bool
}

// NewCapturer 创建新的捕获器
func NewCapturer(iface string, bufferSize int) *Capturer {
	return &Capturer{
		iface:      iface,
		snapLen:    1600, // 足够捕获大多数头部
		promisc:    true, // 混杂模式
		timeout:    pcap.BlockForever,
		packetChan: make(chan *models.PacketMeta, bufferSize),
	}
}

// Start 开始捕获
func (c *Capturer) Start(ctx context.Context) error {
	handle, err := pcap.OpenLive(c.iface, c.snapLen, c.promisc, c.timeout)
	if err != nil {
		return fmt.Errorf("open interface %s: %w", c.iface, err)
	}
	c.handle = handle

	c.mu.Lock()
	c.running = true
	c.mu.Unlock()

	packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
	packetSource.DecodeOptions.Lazy = true
	packetSource.DecodeOptions.NoCopy = true

	go c.processPackets(ctx, packetSource)
	return nil
}

// Stop 停止捕获
func (c *Capturer) Stop() {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.running && c.handle != nil {
		c.handle.Close()
		c.running = false
	}
}

// Packets 返回数据包通道
func (c *Capturer) Packets() <-chan *models.PacketMeta {
	return c.packetChan
}

// processPackets 处理数据包流
func (c *Capturer) processPackets(ctx context.Context, source *gopacket.PacketSource) {
	defer close(c.packetChan)

	for {
		select {
		case <-ctx.Done():
			return
		case packet, ok := <-source.Packets():
			if !ok {
				return
			}
			if meta := c.decodePacket(packet); meta != nil {
				select {
				case c.packetChan <- meta:
				default:
					// 缓冲满，丢弃（避免阻塞捕获）
					log.Println("packet buffer full, dropping")
				}
			}
		}
	}
}

// decodePacket 解码数据包到 PacketMeta
func (c *Capturer) decodePacket(packet gopacket.Packet) *models.PacketMeta {
	meta := &models.PacketMeta{
		Timestamp: packet.Metadata().Timestamp,
	}

	// L3: IP 层
	if ipLayer := packet.Layer(layers.LayerTypeIPv4); ipLayer != nil {
		ip := ipLayer.(*layers.IPv4)
		meta.SrcIP = ip.SrcIP.String()
		meta.DstIP = ip.DstIP.String()
		meta.Protocol = ip.Protocol.String()
	} else if ip6Layer := packet.Layer(layers.LayerTypeIPv6); ip6Layer != nil {
		ip6 := ip6Layer.(*layers.IPv6)
		meta.SrcIP = ip6.SrcIP.String()
		meta.DstIP = ip6.DstIP.String()
		meta.Protocol = ip6.NextHeader.String()
	} else {
		return nil // 非 IP 包，跳过
	}

	// L4: TCP/UDP 层
	if tcpLayer := packet.Layer(layers.LayerTypeTCP); tcpLayer != nil {
		tcp := tcpLayer.(*layers.TCP)
		meta.SrcPort = uint16(tcp.SrcPort)
		meta.DstPort = uint16(tcp.DstPort)
		meta.Protocol = "TCP"
		meta.TCPFlags = formatTCPFlags(tcp)
	} else if udpLayer := packet.Layer(layers.LayerTypeUDP); udpLayer != nil {
		udp := udpLayer.(*layers.UDP)
		meta.SrcPort = uint16(udp.SrcPort)
		meta.DstPort = uint16(udp.DstPort)
		meta.Protocol = "UDP"
	}

	// Payload
	if app := packet.ApplicationLayer(); app != nil {
		payload := app.Payload()
		meta.PayloadLen = len(payload)
		meta.Entropy = calculateEntropy(payload)
	}

	return meta
}

// formatTCPFlags 格式化 TCP 标志位
func formatTCPFlags(tcp *layers.TCP) string {
	var flags []byte
	if tcp.SYN {
		flags = append(flags, 'S')
	}
	if tcp.ACK {
		flags = append(flags, 'A')
	}
	if tcp.FIN {
		flags = append(flags, 'F')
	}
	if tcp.RST {
		flags = append(flags, 'R')
	}
	if tcp.PSH {
		flags = append(flags, 'P')
	}
	if tcp.URG {
		flags = append(flags, 'U')
	}
	return string(flags)
}

// calculateEntropy 计算载荷熵值（用于异常检测）
func calculateEntropy(data []byte) float64 {
	if len(data) == 0 {
		return 0
	}

	var freq [256]int
	for _, b := range data {
		freq[b]++
	}

	var entropy float64
	dataLen := float64(len(data))
	for _, count := range freq {
		if count > 0 {
			p := float64(count) / dataLen
			entropy -= p * math.Log2(p)
		}
	}
	return entropy
}

// ListInterfaces 列出可用网络接口
func ListInterfaces() ([]string, error) {
	devices, err := pcap.FindAllDevs()
	if err != nil {
		return nil, fmt.Errorf("find devices: %w", err)
	}

	var interfaces []string
	for _, dev := range devices {
		interfaces = append(interfaces, dev.Name)
	}
	return interfaces, nil
}
