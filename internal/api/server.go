package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	"netlyra/internal/models"
)

// Server Gin HTTP 服务器
type Server struct {
	router *gin.Engine
	db     *gorm.DB
	hub    *Hub // WebSocket hub
}

// NewServer 创建新的 API 服务器
func NewServer(db *gorm.DB) *Server {
	gin.SetMode(gin.ReleaseMode)
	router := gin.New()
	router.Use(gin.Recovery())

	hub := NewHub()
	go hub.Run()

	s := &Server{
		router: router,
		db:     db,
		hub:    hub,
	}

	s.setupRoutes()
	return s
}

// setupRoutes 配置路由
func (s *Server) setupRoutes() {
	api := s.router.Group("/api/v1")
	{
		api.GET("/health", s.healthCheck)
		api.GET("/alerts", s.listAlerts)
		api.GET("/alerts/:id", s.getAlert)
		api.GET("/connections", s.listConnections)
		api.GET("/stats", s.getStats)
	}

	// WebSocket 端点
	s.router.GET("/ws", func(c *gin.Context) {
		s.hub.HandleWebSocket(c.Writer, c.Request)
	})
}

// Run 启动服务器
func (s *Server) Run(addr string) error {
	return s.router.Run(addr)
}

// Hub 返回 WebSocket hub 用于广播
func (s *Server) Hub() *Hub {
	return s.hub
}

// === Handlers ===

func (s *Server) healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "ok",
		"service": "netlyra-core",
	})
}

func (s *Server) listAlerts(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 50
	}
	offset := (page - 1) * limit

	var alerts []models.Alert
	var total int64

	s.db.Model(&models.Alert{}).Count(&total)
	s.db.Order("timestamp DESC").Offset(offset).Limit(limit).Find(&alerts)

	c.JSON(http.StatusOK, gin.H{
		"data":  alerts,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

func (s *Server) getAlert(c *gin.Context) {
	id := c.Param("id")
	var alert models.Alert
	if err := s.db.First(&alert, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "alert not found"})
		return
	}
	c.JSON(http.StatusOK, alert)
}

func (s *Server) listConnections(c *gin.Context) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "100"))
	if limit < 1 || limit > 500 {
		limit = 100
	}

	var connections []models.Connection
	s.db.Order("last_seen DESC").Limit(limit).Find(&connections)

	c.JSON(http.StatusOK, gin.H{
		"data":  connections,
		"count": len(connections),
	})
}

func (s *Server) getStats(c *gin.Context) {
	var alertCount, connectionCount int64
	s.db.Model(&models.Alert{}).Count(&alertCount)
	s.db.Model(&models.Connection{}).Count(&connectionCount)

	c.JSON(http.StatusOK, gin.H{
		"alerts":      alertCount,
		"connections": connectionCount,
	})
}
