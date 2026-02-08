#!/bin/bash

echo "🚀 启动后端API（修复版）"
echo "======================="
echo ""

# 配置文件
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

# 删除旧的go.sum（如果存在）
rm -f backend/go.sum

echo "✅ 配置已准备"
echo "🔨 启动后端容器..."
echo ""

# 启动后端
docker run -d \
  --name shortdrama-backend \
  --network shortdrama-network \
  -p 8080:8080 \
  -v "$(pwd)/backend:/app" \
  -w /app \
  -e GOPROXY=https://goproxy.io,direct \
  -e GOSUMDB=off \
  golang:1.21-alpine \
  sh -c '
    echo "📦 安装依赖..."
    apk add --no-cache git
    echo "⬇️  初始化Go模块..."
    rm -f go.sum
    go mod tidy
    echo "🔧 直接运行（不编译）..."
    go run main.go
  '

echo "⏳ 等待后端启动（40秒）..."

# 等待并检查
for i in {1..40}; do
  sleep 1
  if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo ""
    echo "✅ 后端API已成功启动！"
    echo ""
    echo "🌐 所有服务已就绪："
    echo "   📱 用户App:    http://localhost"
    echo "   💼 管理后台:   http://localhost:3001"
    echo "   🔧 后端API:    http://localhost:8080"
    echo ""
    echo "👤 管理员登录："
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
    echo ""
    echo "现在可以登录管理后台了！"
    echo ""
    exit 0
  fi
  echo -n "."
done

echo ""
echo "⚠️  启动时间较长，继续检查..."
echo "查看日志："
echo "docker logs -f shortdrama-backend"
