#!/bin/bash

echo "🔄 快速重启前端和管理后台"
echo "=========================="
echo ""

cd /Users/kis/data/cursor_test

# 停止旧容器
echo "停止旧容器..."
docker stop shortdrama-admin shortdrama-frontend 2>/dev/null
docker rm shortdrama-admin shortdrama-frontend 2>/dev/null

# 重建并启动
echo "重建容器..."
docker-compose build admin frontend 2>&1 | grep -E "(Building|Built|CACHED|ERROR)" || true
docker-compose up -d admin frontend

sleep 3

echo ""
echo "✅ 完成！"
echo ""
echo "🧪 测试登录API："
curl -X POST http://localhost:3001/api/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' \
  -w "\nHTTP: %{http_code}\n"
echo ""
