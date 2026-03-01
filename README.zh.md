# NetLyra

**简体中文** | [English](README.md)

利用 AI 驱动的异常检测进行实时网络流量分析。

## 技术栈

- **核心**: Go (gopacket, Gin, GORM)
- **AI引擎**: Python (River ML)
- **消息总线**: Redpanda
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

## 访问端点

- **Redpanda控制台**: [http://localhost:8080](http://localhost:8080)
- **API健康检查**: [http://localhost:8090/api/v1/health](http://localhost:8090/api/v1/health)

## 相关文档

- [架构说明](docs/architecture.md)
- [产品需求文档 (PRD)](PRODUCT_REQUIREMENTS_DOCUMENT.md)

## 技术说明

系统采用完全解耦的架构，Go 负责高速的原始流量捕获与数据库落盘，而 Python 专门维护状态化机器学习流的计算精度。
