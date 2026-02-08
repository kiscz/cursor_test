#!/bin/bash

echo "🚀 启动所有服务（完整版）"
echo "=========================="
echo ""

cd /Users/kis/data/cursor_test

# 步骤1：确保配置文件正确
echo "1️⃣ 准备配置文件..."
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
echo "✅ 配置完成"
echo ""

# 步骤2：停止所有容器
echo "2️⃣ 停止旧容器..."
docker stop shortdrama-backend shortdrama-admin shortdrama-frontend 2>/dev/null
docker rm shortdrama-backend shortdrama-admin shortdrama-frontend 2>/dev/null
echo "✅ 清理完成"
echo ""

# 步骤3：启动数据库和Redis
echo "3️⃣ 确保数据库和Redis运行..."
docker-compose up -d mysql redis
sleep 5
echo "✅ 数据库服务就绪"
echo ""

# 步骤4：构建并启动后端
echo "4️⃣ 构建并启动后端..."
docker-compose build backend
docker-compose up -d backend

echo "⏳ 等待后端启动（30秒）..."
for i in {1..30}; do
  sleep 1
  if curl -s http://localhost:9090/health > /dev/null 2>&1; then
    echo ""
    echo "✅ 后端启动成功！"
    break
  fi
  printf "."
done
echo ""

# 步骤5：启动前端
echo "5️⃣ 启动前端和管理后台..."
docker-compose up -d frontend admin
sleep 5
echo "✅ 前端服务已启动"
echo ""

# 步骤6：测试所有服务
echo "6️⃣ 测试所有服务..."
echo ""
echo "📊 容器状态："
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep shortdrama
echo ""

echo "🧪 API测试："
echo -n "  后端健康检查: "
if curl -s http://localhost:9090/health > /dev/null 2>&1; then
    echo "✅"
else
    echo "❌"
fi

echo -n "  管理后台访问: "
if curl -s http://localhost:3001 > /dev/null 2>&1; then
    echo "✅"
else
    echo "❌"
fi

echo -n "  用户端访问:   "
if curl -s http://localhost > /dev/null 2>&1; then
    echo "✅"
else
    echo "❌"
fi
echo ""

# 步骤7：显示结果
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 🎉 部署完成！"
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
echo "📋 有用的命令："
echo "   查看所有容器: docker ps"
echo "   查看后端日志: docker logs -f shortdrama-backend"
echo "   重启后端:     docker restart shortdrama-backend"
echo "   停止所有:     docker-compose down"
echo ""
