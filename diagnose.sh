#!/bin/bash

echo "🔍 诊断后端问题"
echo "================"
echo ""

echo "1️⃣ 容器状态："
docker ps -a --filter name=shortdrama-backend --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "2️⃣ 容器是否在运行："
docker inspect shortdrama-backend --format='{{.State.Running}}' 2>/dev/null || echo "容器不存在"
echo ""

echo "3️⃣ 最新日志（最后30行）："
docker logs shortdrama-backend 2>&1 | tail -30
echo ""

echo "4️⃣ 测试健康检查："
curl -v http://localhost:8080/health 2>&1 | head -20
echo ""
