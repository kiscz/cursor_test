#!/bin/bash

echo "🔧 重新打包并重启后端（带超详细日志）"
echo "========================================"
echo ""

echo "1️⃣ 停止并删除现有后端容器："
docker stop shortdrama-backend 2>/dev/null
docker rm shortdrama-backend 2>/dev/null
echo "✅ 已清理"
echo ""

echo "2️⃣ 重新构建后端镜像："
cd /Users/kis/data/cursor_test
docker build -t shortdrama-backend:latest -f backend/Dockerfile backend/ 2>&1 | tail -10

if [ $? -ne 0 ]; then
    echo "❌ 构建失败"
    exit 1
fi

echo ""
echo "✅ 构建成功"
echo ""

echo "3️⃣ 启动新的后端容器："
docker run -d \
    --name shortdrama-backend \
    --network shortdrama-network \
    -p 9090:9090 \
    -v /Users/kis/data/cursor_test/backend/config.yaml:/root/config.yaml:ro \
    shortdrama-backend:latest

echo "✅ 已启动"
echo ""

echo "4️⃣ 等待后端就绪..."
sleep 5

echo ""
echo "5️⃣ 检查后端健康状态："
curl -s http://localhost:9090/health && echo " ✅ 后端正常" || echo " ❌ 后端异常"

echo ""
echo ""
echo "6️⃣ 测试登录（将输出详细调试日志）："
sleep 2

curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}' | head -c 200

echo ""
echo ""
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "后端详细日志："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker logs shortdrama-backend 2>&1 | grep -A 50 "DEBUG-PASSWORD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
