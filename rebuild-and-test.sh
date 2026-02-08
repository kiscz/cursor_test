#!/bin/bash

echo "🔧 重新构建后端（带调试日志）并测试"
echo "========================================"
echo ""

echo "1️⃣ 停止现有后端："
docker stop shortdrama-backend 2>&1 | grep -v "is not running"
docker rm shortdrama-backend 2>&1 | grep -v "No such container"

echo "✅ 已停止"
echo ""

echo "2️⃣ 重新构建后端镜像（带调试日志）："
cd /Users/kis/data/cursor_test
docker build -t shortdrama-backend:latest -f backend/Dockerfile backend/ 2>&1 | tail -10

echo ""
echo "3️⃣ 启动新后端容器："
docker run -d \
    --name shortdrama-backend \
    --network shortdrama-network \
    -p 9090:9090 \
    -v /Users/kis/data/cursor_test/backend/config.yaml:/root/config.yaml:ro \
    shortdrama-backend:latest

echo "✅ 已启动"
echo ""

echo "4️⃣ 等待后端启动..."
sleep 5

echo ""
echo "5️⃣ 检查后端状态："
curl -s http://localhost:9090/health && echo " ✅" || echo " ❌"

echo ""
echo "6️⃣ 测试登录（查看调试日志）："
sleep 2

curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}' | head -c 200

echo ""
echo ""
echo "7️⃣ 后端调试日志："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker logs shortdrama-backend 2>&1 | grep -E "\[DEBUG\]|Invalid|password" | tail -15
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "8️⃣ 完整后端日志（最后20行）："
docker logs shortdrama-backend 2>&1 | tail -20

echo ""
