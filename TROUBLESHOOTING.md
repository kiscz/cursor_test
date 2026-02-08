# 后端启动故障排除指南

## 问题：后端容器启动但无法访问

### 可能原因及解决方案

#### 1. Go模块下载缓慢
**现象**：容器启动后长时间无响应

**解决方案**：
```bash
# 查看日志确认是否卡在下载模块
docker logs shortdrama-backend

# 如果看到 "downloading..." 很久没动，重启容器使用国内代理
docker stop shortdrama-backend
docker rm shortdrama-backend

docker run -d \
  --name shortdrama-backend \
  --network shortdrama-network \
  -p 9090:9090 \
  -v "$(pwd)/backend:/app" \
  -w /app \
  -e GOPROXY=https://goproxy.cn,direct \
  -e CGO_ENABLED=0 \
  golang:1.21-alpine \
  sh -c '
    apk add --no-cache git
    go mod download
    go run main.go
  '
```

#### 2. 数据库连接失败
**现象**：日志显示 "dial tcp" 或 "connection refused"

**解决方案**：
```bash
# 检查MySQL容器是否运行
docker ps | grep mysql

# 如果MySQL未运行，启动它
docker start shortdrama-mysql

# 重启后端
docker restart shortdrama-backend
```

#### 3. 端口被占用
**现象**：无法绑定端口

**解决方案**：
```bash
# 检查9090端口
lsof -i :9090

# 如果被占用，kill 进程或换个端口（比如9091）
# 编辑 backend/config.yaml，将 port: 9090 改为 port: 9091
# 然后重启容器，映射新端口：
docker run -d \
  --name shortdrama-backend \
  --network shortdrama-network \
  -p 9091:9091 \
  ...
```

#### 4. go.sum 文件问题
**现象**：日志显示 "checksum mismatch" 或 "SECURITY ERROR"

**解决方案**：
```bash
# 删除go.sum，让Go重新生成
rm -f backend/go.sum

# 重启后端
docker stop shortdrama-backend
docker rm shortdrama-backend
./run-backend-9090.sh
```

#### 5. Docker网络问题
**现象**：容器运行但无法连接到MySQL/Redis

**解决方案**：
```bash
# 检查网络
docker network ls | grep shortdrama

# 重新创建网络
docker network rm shortdrama-network 2>/dev/null
docker network create shortdrama-network

# 确保MySQL和Redis在同一网络
docker network connect shortdrama-network shortdrama-mysql
docker network connect shortdrama-network shortdrama-redis

# 重启后端
docker restart shortdrama-backend
```

## 快速诊断命令

一行命令查看所有关键信息：
```bash
echo "=== 容器状态 ===" && \
docker ps -a | grep shortdrama && \
echo -e "\n=== 后端日志（最后20行）===" && \
docker logs --tail 20 shortdrama-backend 2>&1 && \
echo -e "\n=== 端口占用 ===" && \
lsof -i :9090 && \
echo -e "\n=== 健康检查 ===" && \
curl -v http://localhost:9090/health 2>&1 | head -10
```

## 终极方案：使用预编译镜像

如果上述方案都失败，使用Dockerfile构建完整镜像：

```bash
cd /Users/kis/data/cursor_test

# 确保go.sum存在（在容器内生成）
docker run --rm \
  -v "$(pwd)/backend:/app" \
  -w /app \
  -e GOPROXY=https://goproxy.cn,direct \
  golang:1.21-alpine \
  sh -c 'apk add --no-cache git && go mod tidy'

# 构建镜像
cd backend
docker build -t shortdrama-backend:v1 .

# 运行
docker stop shortdrama-backend 2>/dev/null
docker rm shortdrama-backend 2>/dev/null

docker run -d \
  --name shortdrama-backend \
  --network shortdrama-network \
  -p 9090:9090 \
  -v "$(pwd)/config.yaml:/root/config.yaml" \
  shortdrama-backend:v1
```

## 检查成功标志

当看到以下内容时，说明后端启动成功：
```
[GIN-debug] Listening and serving HTTP on :9090
```

或者访问 http://localhost:9090/health 返回：
```json
{"status":"ok"}
```
