#!/bin/bash

echo "🚀 使用Dockerfile构建并运行后端"
echo "===================================="
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
echo ""

# 停止并删除旧容器
echo "🧹 清理旧容器..."
docker stop shortdrama-backend 2>/dev/null || true
docker rm shortdrama-backend 2>/dev/null || true
echo ""

# 删除go.sum让Docker重新生成
rm -f backend/go.sum

echo "🔨 构建Docker镜像（这可能需要几分钟）..."
cd backend
docker build -t shortdrama-backend:latest . --no-cache
BUILD_EXIT=$?
cd ..

if [ $BUILD_EXIT -ne 0 ]; then
  echo "❌ 构建失败"
  exit 1
fi

echo ""
echo "✅ 镜像构建成功！"
echo ""

echo "🚀 启动后端容器..."
docker run -d \
  --name shortdrama-backend \
  --network shortdrama-network \
  -p 8080:8080 \
  -v "$(pwd)/backend/config.yaml:/root/config.yaml" \
  shortdrama-backend:latest

echo ""
echo "⏳ 等待后端启动（最多30秒）..."
echo ""

for i in {1..30}; do
  sleep 1
  if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ 🎉 后端API启动成功！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 所有服务："
    echo "   📱 用户端:     http://localhost"
    echo "   💼 管理后台:   http://localhost:3001"
    echo "   🔧 后端API:    http://localhost:8080"
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
echo "⚠️  超时，但容器可能还在启动..."
echo "查看日志: docker logs -f shortdrama-backend"
