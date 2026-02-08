#!/bin/bash

echo "🔧 快速重建前端"
echo "==============="
echo ""

cd /Users/kis/data/cursor_test

echo "1️⃣ 停止容器..."
docker stop shortdrama-frontend 2>/dev/null
docker rm shortdrama-frontend 2>/dev/null

echo ""
echo "2️⃣ 重新构建..."
docker build -t shortdrama-frontend:latest -f frontend/Dockerfile frontend/ 2>&1 | tail -15

echo ""
echo "3️⃣ 启动容器..."
docker run -d \
    --name shortdrama-frontend \
    --network shortdrama-network \
    -p 3000:80 \
    shortdrama-frontend:latest

sleep 3

echo ""
echo "✅ 完成！访问 http://localhost:3000"
echo ""
