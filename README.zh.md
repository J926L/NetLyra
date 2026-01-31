# NetLyra

**简体中文** | [English](README.md)

利用 AI 驱动的异常检测进行实时网络流量分析。

## 技术栈

- **核心引擎**: Go (gopacket, Gin, GORM)
- **AI 算法**: Python (River ML)
- **用户界面**: Flutter
- **消息队列**: Redpanda
- **存储**: SQLite

## 快速启动 (Docker)

```bash
docker compose up -d
```

> [!NOTE]
> 核心服务使用 `network_mode: host` 进行数据包捕获，需要 `NET_RAW` 权限。

## 快速启动 (开发)

```bash
# 安装依赖
go mod tidy
cd engine && uv sync

# 启动 Redpanda (请根据您的基础设施位置调整路径)
docker compose -f /path/to/redpanda/docker-compose.yml up -d

# 运行数据库迁移
task db:sync

# 启动开发环境
task dev:all
```

## 服务访问

- **Web 仪表盘**: [http://localhost:8085](http://localhost:8085)
- **Redpanda 控制台**: [http://localhost:8080](http://localhost:8080)
- **API 健康检查**: [http://localhost:8090/api/v1/health](http://localhost:8090/api/v1/health)

## 相关文档

- [架构说明](docs/architecture.md)
- [产品需求文档 (PRD)](PRODUCT_REQUIREMENTS_DOCUMENT.md)

## 技术备注

UI 层选择了 Flutter，以利用其统一的代码库架构。这使得从单一源代码进行跨平台部署成为可能，同时保持了以 Web 为核心的开发重点。
