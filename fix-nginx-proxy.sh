#!/bin/bash

echo "🔧 修复Nginx代理配置"
echo "=========================="
echo ""

cd /Users/kis/data/cursor_test

echo "📝 问题说明："
echo "   之前使用 host.docker.internal，但在Docker网络中应该使用容器名"
echo "   已修改为: http://shortdrama-backend:9090"
echo ""

# 停止并删除旧容器
echo "1️⃣ 停止旧的前端和管理后台容器..."
docker stop shortdrama-admin shortdrama-frontend 2>/dev/null
docker rm shortdrama-admin shortdrama-frontend 2>/dev/null
echo "✅ 旧容器已清理"
echo ""

# 重建容器（会使用新的nginx.conf）
echo "2️⃣ 重建管理后台容器..."
docker-compose build admin
docker-compose up -d admin
echo "✅ 管理后台已重启"
echo ""

echo "3️⃣ 重建前端容器..."
docker-compose build frontend
docker-compose up -d frontend
echo "✅ 前端已重启"
echo ""

# 等待容器启动
echo "⏳ 等待容器启动..."
sleep 5
echo ""

# 测试API连接
echo "4️⃣ 测试API连接..."
echo ""

echo "📊 容器状态："
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep shortdrama
echo ""

echo "🧪 从容器内测试后端连接："
echo -n "  管理后台 -> 后端: "
docker exec shortdrama-admin wget -q -O- http://shortdrama-backend:9090/health 2>/dev/null && echo "✅" || echo "❌"
echo ""

echo "🧪 从浏览器测试（通过Nginx代理）："
echo -n "  http://localhost:3001/api/health: "
curl -s http://localhost:3001/api/health > /dev/null 2>&1 && echo "✅" || echo "❌"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 修复完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 现在可以测试登录了："
echo "   访问: http://localhost:3001"
echo "   邮箱: admin@example.com"
echo "   密码: admin123"
echo ""
echo "📋 如果还有问题，请查看日志："
echo "   docker logs shortdrama-backend"
echo "   docker logs shortdrama-admin"
echo ""
