#!/bin/bash

echo "🔧 修复go.sum并启动后端（端口9090）"
echo "======================================="
echo ""

# 配置文件
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

echo "✅ 配置已准备"
echo ""

# 步骤1：生成正确的go.sum
echo "📦 步骤1：生成go.sum文件..."
rm -f backend/go.sum

docker run --rm \
  -v "$(pwd)/backend:/app" \
  -w /app \
  -e GOPROXY=https://goproxy.cn,direct \
  golang:1.21-alpine \
  sh -c '
    echo "安装git..."
    apk add --no-cache git > /dev/null 2>&1
    echo "生成go.sum..."
    go mod tidy
    echo "✅ go.sum已生成"
  '

if [ ! -f backend/go.sum ]; then
  echo "❌ go.sum生成失败"
  exit 1
fi

echo "✅ go.sum已就绪"
echo ""

# 步骤2：启动后端
echo "🚀 步骤2：启动后端容器..."
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
    echo "📦 安装git..."
    apk add --no-cache git > /dev/null 2>&1
    
    echo "⬇️  下载依赖..."
    go mod download
    
    echo "🚀 启动应用..."
    exec go run main.go
  '

if [ $? -ne 0 ]; then
  echo "❌ 容器启动失败"
  exit 1
fi

echo "✅ 容器已启动"
echo ""
echo "⏳ 等待后端就绪（60秒）..."
echo ""

# 等待健康检查
for i in {1..60}; do
  sleep 1
  if curl -s http://localhost:9090/health > /dev/null 2>&1; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ 🎉 后端启动成功！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 访问地址："
    echo "   📱 用户端:     http://localhost"
    echo "   💼 管理后台:   http://localhost:3001"
    echo "   🔧 后端API:    http://localhost:9090"
    echo ""
    echo "👤 管理员登录："
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
    echo ""
    echo "🎬 现在可以登录使用了！"
    echo ""
    exit 0
  fi
  printf "."
done

echo ""
echo ""
echo "⚠️  健康检查超时，但容器可能仍在启动中..."
echo ""
echo "📋 查看日志："
echo "   docker logs -f shortdrama-backend"
echo ""
echo "🧪 手动测试："
echo "   curl http://localhost:9090/health"
echo ""
echo "   或打开测试页面："
echo "   open test-backend.html"
echo ""
