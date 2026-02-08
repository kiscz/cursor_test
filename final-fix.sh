#!/bin/bash

echo "🎯 最终修复方案"
echo "=========================="
echo ""

cd /Users/kis/data/cursor_test

# 步骤1：确认nginx配置正确
echo "1️⃣ 检查nginx配置..."
echo "Admin nginx.conf:"
grep -A 2 "location /api/" admin/nginx.conf
echo ""

# 步骤2：完全重建admin和frontend容器
echo "2️⃣ 完全重建容器（包括镜像）..."
docker stop shortdrama-admin shortdrama-frontend 2>/dev/null
docker rm shortdrama-admin shortdrama-frontend 2>/dev/null

# 删除旧镜像强制重建
docker rmi cursor_test-admin cursor_test-frontend 2>/dev/null

# 重建
docker-compose build --no-cache admin frontend
docker-compose up -d admin frontend

echo ""
echo "⏳ 等待容器启动（10秒）..."
sleep 10

# 步骤3：验证容器内的nginx配置
echo ""
echo "3️⃣ 验证容器内的nginx配置..."
docker exec shortdrama-admin cat /etc/nginx/conf.d/default.conf | grep -A 3 "location /api"
echo ""

# 步骤4：测试连接
echo "4️⃣ 测试连接..."
echo ""

echo "📊 容器状态："
docker ps --format "table {{.Names}}\t{{.Status}}" | grep shortdrama
echo ""

echo "🔍 测试后端直接访问："
curl -s --max-time 5 http://localhost:9090/api/admin/auth/login \
  -X POST -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' | head -c 200
echo ""
echo ""

echo "🔍 测试通过admin nginx代理："
curl -s --max-time 5 http://localhost:3001/api/admin/auth/login \
  -X POST -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' | head -c 200
echo ""
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 修复完成！"
echo ""
echo "🌐 现在访问 http://localhost:3001 测试登录"
echo "   邮箱: admin@example.com"
echo "   密码: admin123"
echo ""
echo "📋 如果还有问题，请告诉我看到的错误信息"
echo ""
