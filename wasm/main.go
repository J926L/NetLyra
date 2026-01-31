//go:build js && wasm

package main

import (
	"encoding/json"
	"math"
	"syscall/js"
)

// PacketInfo minimal packet structure for WASM
type PacketInfo struct {
	SrcIP      string  `json:"src_ip"`
	DstIP      string  `json:"dst_ip"`
	SrcPort    uint16  `json:"src_port"`
	DstPort    uint16  `json:"dst_port"`
	Protocol   string  `json:"proto"`
	PayloadLen int     `json:"payload_len"`
	Entropy    float64 `json:"entropy"`
}

// calculateEntropy computes Shannon entropy of byte slice
func calculateEntropy(data []byte) float64 {
	if len(data) == 0 {
		return 0
	}

	freq := make(map[byte]int)
	for _, b := range data {
		freq[b]++
	}

	var entropy float64
	length := float64(len(data))
	for _, count := range freq {
		p := float64(count) / length
		entropy -= p * math.Log2(p)
	}
	return entropy
}

// parsePacket parses JSON packet metadata
func parsePacket(jsonStr string) (*PacketInfo, error) {
	var pkt PacketInfo
	if err := json.Unmarshal([]byte(jsonStr), &pkt); err != nil {
		return nil, err
	}
	return &pkt, nil
}

// jsCalculateEntropy exposes entropy calculation to JavaScript
func jsCalculateEntropy(this js.Value, args []js.Value) interface{} {
	if len(args) < 1 {
		return js.ValueOf(-1)
	}
	data := args[0].String()
	entropy := calculateEntropy([]byte(data))
	return js.ValueOf(entropy)
}

// jsParsePacket exposes packet parsing to JavaScript
func jsParsePacket(this js.Value, args []js.Value) interface{} {
	if len(args) < 1 {
		return js.Null()
	}
	jsonStr := args[0].String()
	pkt, err := parsePacket(jsonStr)
	if err != nil {
		return js.Null()
	}

	result := map[string]interface{}{
		"src_ip":      pkt.SrcIP,
		"dst_ip":      pkt.DstIP,
		"src_port":    pkt.SrcPort,
		"dst_port":    pkt.DstPort,
		"proto":       pkt.Protocol,
		"payload_len": pkt.PayloadLen,
		"entropy":     pkt.Entropy,
	}
	return js.ValueOf(result)
}

func main() {
	c := make(chan struct{})

	// Register functions
	js.Global().Set("netlyraCalculateEntropy", js.FuncOf(jsCalculateEntropy))
	js.Global().Set("netlyraParsePacket", js.FuncOf(jsParsePacket))

	println("NetLyra WASM module loaded")
	<-c
}
