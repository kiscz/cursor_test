#!/bin/bash

echo "🚀 启动后端API服务（使用Docker）"
echo "================================"

# 检查MySQL和Redis是否运行
if ! docker ps | grep -q shortdrama-mysql; then
    echo "❌ MySQL容器未运行，请先启动数据库"
    exit 1
fi

if ! docker ps | grep -q shortdrama-redis; then
    echo "❌ Redis容器未运行，请先启动Redis"
    exit 1
fi

echo "✅ 数据库服务正在运行"

# 确保配置文件存在
if [ ! -f "backend/config.yaml" ]; then
    echo "📝 创建后端配置文件..."
    cat > backend/config.yaml << 'EOF'
server:
  port: 8080
  mode: debug

database:
  host: host.docker.internal
  port: 3306
  user: root
  password: rootpassword
  dbname: short_drama
  max_idle_conns: 10
  max_open_conns: 100

redis:
  host: host.docker.internal
  port: 6379
  password: ""
  db: 0

jwt:
  secret: demo_secret_key_change_in_production
  expires_hours: 720

stripe:
  secret_key: sk_test_demo
  webhook_secret: whsec_demo
  price_monthly: price_demo
  price_yearly: price_demo

aws:
  region: us-east-1
  access_key_id: demo
  secret_access_key: demo
  s3_bucket: demo
  cloudfront_domain: ""

admob:
  app_id: ca-app-pub-demo
  rewarded_ad_unit_id: ca-app-pub-demo

cors:
  allowed_origins:
    - http://localhost
    - http://localhost:80
    - http://localhost:3000
    - http://localhost:3001
  allow_credentials: true
EOF
    echo "✅ 配置文件已创建"
fi

# 停止可能存在的旧容器
docker stop shortdrama-backend 2>/dev/null
docker rm shortdrama-backend 2>/dev/null

echo ""
echo "🔨 启动后端API容器..."

# 使用官方Go镜像直接运行
docker run -d \
  --name shortdrama-backend \
  --network shortdrama-network \
  -p 8080:8080 \
  -v "$(pwd)/backend:/app" \
  -w /app \
  golang:1.21-alpine \
  sh -c "apk add --no-cache git && go mod download && go run main.go"

echo ""
echo "⏳ 等待后端启动..."
sleep 5

# 检查后端状态
if docker ps | grep -q shortdrama-backend; then
    echo "✅ 后端API已启动！"
    echo ""
    echo "🌐 服务地址："
    echo "   后端API:    http://localhost:8080"
    echo "   前端App:    http://localhost:80"
    echo "   管理后台:   http://localhost:3001"
    echo ""
    echo "👤 默认管理员："
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
    echo ""
    echo "📝 查看后端日志："
    echo "   docker logs -f shortdrama-backend"
else
    echo "❌ 后端启动失败，查看日志："
    echo "   docker logs shortdrama-backend"
    exit 1
fi
