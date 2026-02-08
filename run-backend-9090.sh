#!/bin/bash

echo "🚀 启动后端（端口9090）"
echo "========================"
echo ""

# 配置文件 - 使用9090端口
cat > backend/config.yaml << 'EOF'
server:
  port: 9090
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
  secret: demo_secret_key_for_development
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

admob:
  app_id: demo
  rewarded_ad_unit_id: demo

cors:
  allowed_origins:
    - http://localhost
    - http://localhost:80
    - http://localhost:3000
    - http://localhost:3001
  allow_credentials: true
EOF

echo "✅ 配置已准备（端口9090）"
echo "🚀 启动后端容器..."
echo ""

# 清理go.sum
rm -f backend/go.sum

# 启动容器 - 映射到9090端口
docker run -d \
  --name shortdrama-backend \
  --network shortdrama-network \
  -p 9090:9090 \
  -v "$(pwd)/backend:/app" \
  -w /app \
  -e CGO_ENABLED=0 \
  golang:1.21-alpine \
  sh -c '
    set -e
    echo "📦 安装git..."
    apk add --no-cache git > /dev/null 2>&1
    
    echo "⬇️  初始化模块..."
    go mod download
    
    echo "🚀 启动应用（端口9090）..."
    exec go run main.go
  '

echo "⏳ 等待后端启动（60秒）..."
echo ""

for i in {1..60}; do
  sleep 1
  if curl -s http://localhost:9090/health > /dev/null 2>&1; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ 🎉 后端API启动成功！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 所有服务："
    echo "   📱 用户端:     http://localhost"
    echo "   💼 管理后台:   http://localhost:3001"
    echo "   🔧 后端API:    http://localhost:9090"
    echo ""
    echo "👤 管理员登录："
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
    echo ""
    exit 0
  fi
  printf "."
done

echo ""
echo "⚠️  超时。检查状态："
echo "docker logs shortdrama-backend"
