#!/bin/bash

echo "🚀 启动后端API（终极简化版）"
echo "=============================="
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

echo "✅ 配置已准备"
echo "🔨 清理并启动后端容器..."
echo ""

# 清理旧的 go.sum
rm -f backend/go.sum

# 启动后端 - 一步到位
docker run -d \
  --name shortdrama-backend \
  --network shortdrama-network \
  -p 8080:8080 \
  -v "$(pwd)/backend:/app" \
  -w /app \
  golang:1.21-alpine \
  sh -c '
    echo "📦 安装依赖..."
    apk add --no-cache git gcc musl-dev
    
    echo "⬇️  下载所有Go模块..."
    go mod download
    
    echo "🔧 编译应用..."
    go build -o main .
    
    echo "🚀 启动服务器..."
    ./main
  '

echo "⏳ 等待后端启动（最多60秒）..."
echo ""

# 等待并检查
for i in {1..60}; do
  sleep 1
  if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ 🎉 所有服务启动成功！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 访问地址："
    echo "   📱 用户端:     http://localhost"
    echo "   💼 管理后台:   http://localhost:3001"
    echo "   🔧 后端API:    http://localhost:8080"
    echo ""
    echo "👤 管理员登录信息："
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
    echo ""
    echo "🎬 现在可以登录并开始使用了！"
    echo ""
    exit 0
  fi
  printf "."
done

echo ""
echo ""
echo "⚠️  后端启动时间较长..."
echo "📋 查看详细日志："
echo "   docker logs -f shortdrama-backend"
echo ""
