# Docker 一键部署指南

本项目使用 Docker Compose 编排 **MySQL、Redis、Go 后端、用户端前端、管理端前端**，一键启动全部服务。

## 前置要求

- 已安装 [Docker](https://www.docker.com/get-started) 与 [Docker Compose](https://docs.docker.com/compose/install/)
- 本地已克隆代码并进入项目根目录

## 一键启动

```bash
# 在项目根目录执行
docker compose up -d --build
```

首次会构建镜像并拉取 MySQL/Redis，等待 1～2 分钟后再访问。

## 服务与端口

| 服务     | 端口 | 说明           |
|----------|------|----------------|
| 用户端   | 80   | http://localhost |
| 管理后台 | 3001 | http://localhost:3001 |
| 后端 API | 9090 | http://localhost:9090（供前端代理，一般不直接访问） |
| MySQL    | 3306 | 仅容器内或本机调试用 |
| Redis    | 6379 | 仅容器内或本机调试用 |

- **用户端**、**管理端** 的 `/api/` 会代理到后端容器 `shortdrama-backend:9090`，无需改前端配置。

## 常用命令

```bash
# 启动（后台）
docker compose up -d --build

# 查看日志
docker compose logs -f

# 只看后端日志
docker compose logs -f backend

# 停止
docker compose down

# 停止并删除数据卷（会清空 MySQL 数据）
docker compose down -v
```

## 自定义配置（可选）

- **后端配置**：镜像内已包含 `config.docker.yaml`（数据库 host 为 `mysql`/`redis`，端口 9090）。  
  若需自定义（如改 DB 密码、JWT secret）：
  1. 复制 `backend/config.docker.yaml` 为 `backend/config.yaml` 并修改；
  2. 在 `docker-compose.yml` 中取消 backend 的 `volumes` 注释，挂载 `./backend/config.yaml`。

- **MySQL**：默认库名 `short_drama`，root 密码在 `docker-compose.yml` 的 `MYSQL_ROOT_PASSWORD`，与 `config.docker.yaml` 中的 `database.password` 一致（默认 `rootpassword`）。改密码时请两边一起改。

## 生产环境注意

- 修改 `backend/config.yaml`（或 `config.docker.yaml`）中的 `jwt.secret`、数据库密码等敏感信息。
- 生产建议使用外部 MySQL/Redis 或云数据库，在配置中填写对应 host/port/password，并视情况只部署 backend + 前端，不启动 compose 中的 mysql/redis 服务。

## 故障排查

- **后端连不上数据库**：确认 MySQL 已通过 healthcheck（`docker compose ps` 中 mysql 为 healthy），再查看 `docker compose logs backend`。
- **前端 502 / 无法访问接口**：确认 backend 已启动且监听 9090：`docker compose logs backend` 中应有 `Server starting on :9090`。
- **端口被占用**：在 `docker-compose.yml` 中修改对应服务的 `ports`（如 `"8080:80"`）。
