#!/bin/bash

echo "🔍 快速诊断并修复后端"
echo "======================"
echo ""

# 检查后端容器状态
echo "1️⃣ 检查容器状态："
docker ps -a | grep shortdrama-backend
echo ""

# 查看日志
echo "2️⃣ 查看最新日志："
docker logs shortdrama-backend 2>&1 | tail -20
echo ""

# 停止并删除旧容器
echo "3️⃣ 清理旧容器..."
docker stop shortdrama-backend 2>/dev/null
docker rm shortdrama-backend 2>/dev/null

# 确保配置文件存在
echo "4️⃣ 准备配置文件..."
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

# 启动后端
echo "5️⃣ 启动后端..."
docker-compose up -d backend

echo ""
echo "⏳ 等待后端启动（30秒）..."
for i in {1..30}; do
  sleep 1
  if curl -s http://localhost:9090/health > /dev/null 2>&1; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ 🎉 后端启动成功！"
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
echo "⚠️  超时，但容器可能还在启动中"
echo ""
echo "🔍 请查看日志："
echo "   docker logs -f shortdrama-backend"
echo ""
