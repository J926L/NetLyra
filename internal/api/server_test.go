package api

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"

	"netlyra/internal/models"
)

func setupTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatalf("Failed to open test memory DB: %v", err)
	}

	err = db.AutoMigrate(&models.Alert{}, &models.Connection{})
	if err != nil {
		t.Fatalf("Failed to migrate test DB: %v", err)
	}

	return db
}

func setupTestServer(db *gorm.DB) *Server {
	return NewServer(db)
}

func TestHealthCheck(t *testing.T) {
	db := setupTestDB(t)
	server := setupTestServer(db)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/api/v1/health", nil)
	server.router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d", w.Code)
	}

	var response map[string]string
	err := json.Unmarshal(w.Body.Bytes(), &response)
	if err != nil {
		t.Fatalf("Failed to parse response JSON: %v", err)
	}

	if response["status"] != "ok" {
		t.Errorf("Expected status ok, got %v", response["status"])
	}
}

func TestGetStats(t *testing.T) {
	db := setupTestDB(t)

	// Insert dummy data
	db.Create(&models.Alert{
		Timestamp: time.Now(),
		SrcIP:     "192.168.1.1",
		DstIP:     "10.0.0.1",
		Protocol:  "TCP",
		Score:     0.9,
	})

	db.Create(&models.Connection{
		FiveTuple:   "192.168.1.1:1234-10.0.0.1:80-TCP",
		PacketCount: 100,
		ByteCount:   5000,
		FirstSeen:   time.Now(),
		LastSeen:    time.Now(),
	})

	server := setupTestServer(db)

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/api/v1/stats", nil)
	server.router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Errorf("Expected status 200, got %d", w.Code)
	}

	var response map[string]int64
	err := json.Unmarshal(w.Body.Bytes(), &response)
	if err != nil {
		t.Fatalf("Failed to parse response JSON: %v", err)
	}

	if response["alerts"] != 1 {
		t.Errorf("Expected 1 alert stat, got %d", response["alerts"])
	}

	if response["connections"] != 1 {
		t.Errorf("Expected 1 connection stat, got %d", response["connections"])
	}
}
