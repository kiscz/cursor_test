#!/bin/bash

echo "🔧 重新构建后端和管理后台（Drama列表优化）"
echo "============================================="
echo ""

echo "1️⃣ 重新构建后端..."
docker stop shortdrama-backend 2>/dev/null
docker rm shortdrama-backend 2>/dev/null

cd /Users/kis/data/cursor_test
docker build -t shortdrama-backend:latest -f backend/Dockerfile backend/ 2>&1 | tail -10

echo ""
echo "2️⃣ 启动后端..."
docker run -d \
    --name shortdrama-backend \
    --network shortdrama-network \
    -p 9090:9090 \
    -v /Users/kis/data/cursor_test/backend/config.yaml:/root/config.yaml:ro \
    shortdrama-backend:latest

sleep 3
echo "✅ 后端已启动"
echo ""

echo "3️⃣ 重新构建管理后台..."
docker stop shortdrama-admin 2>/dev/null
docker rm shortdrama-admin 2>/dev/null

docker build -t shortdrama-admin:latest -f admin/Dockerfile admin/ 2>&1 | tail -10

echo ""
echo "4️⃣ 启动管理后台..."
docker run -d \
    --name shortdrama-admin \
    --network shortdrama-network \
    -p 3001:80 \
    shortdrama-admin:latest

sleep 2
echo "✅ 管理后台已启动"
echo ""

echo "5️⃣ 检查服务状态..."
echo ""
echo "后端健康检查:"
curl -s http://localhost:9090/health && echo " ✅" || echo " ❌"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 更新完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "新功能："
echo "  ✨ 管理后台现在显示所有状态的Drama"
echo "  ✨ 可以按状态筛选（All/Published/Draft/Ongoing/Completed/Archived）"
echo "  ✨ 支持搜索功能"
echo "  ✨ 显示总数和分页"
echo ""
echo "访问管理后台: http://localhost:3001/dramas"
echo "登录凭据: admin@example.com / admin123"
echo ""
