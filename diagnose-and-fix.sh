#!/bin/bash

echo "🔍 诊断并修复登录问题"
echo "=========================="
echo ""

cd /Users/kis/data/cursor_test

# 1. 检查所有容器状态
echo "1️⃣ 容器状态："
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep shortdrama
echo ""

# 2. 检查后端是否响应
echo "2️⃣ 后端健康检查："
echo -n "  直接访问9090端口: "
curl -s --max-time 3 http://localhost:9090/health && echo " ✅" || echo " ❌"
echo ""

# 3. 从容器内测试后端
echo "3️⃣ 容器间通信测试："
echo -n "  admin -> backend: "
docker exec shortdrama-admin wget -q -O- --timeout=3 http://shortdrama-backend:9090/health 2>/dev/null && echo "✅" || echo "❌"
echo ""

# 4. 测试Nginx代理
echo "4️⃣ Nginx代理测试："
echo -n "  通过3001端口: "
timeout 3 curl -s http://localhost:3001/api/health > /dev/null && echo "✅" || echo "❌"
echo ""

# 5. 测试管理员登录API
echo "5️⃣ 登录API测试："
echo "请求: POST http://localhost:3001/api/admin/auth/login"
timeout 5 curl -X POST http://localhost:3001/api/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' \
  2>&1 | head -5
echo ""

# 6. 检查后端日志
echo "6️⃣ 后端最近日志："
docker logs shortdrama-backend --tail 20 2>&1 | tail -10
echo ""

# 7. 检查admin nginx配置
echo "7️⃣ Admin Nginx配置："
docker exec shortdrama-admin cat /etc/nginx/conf.d/default.conf | grep -A 5 "location /api"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 诊断完成"
echo ""
echo "💡 常见问题和解决方案："
echo ""
echo "❌ 如果后端健康检查失败："
echo "   docker restart shortdrama-backend"
echo ""
echo "❌ 如果容器间通信失败："
echo "   检查Docker网络: docker network inspect shortdrama-network"
echo ""
echo "❌ 如果Nginx代理失败："
echo "   重建admin: docker-compose build admin && docker-compose up -d admin"
echo ""
echo "❌ 如果登录返回404："
echo "   后端路由可能有问题，查看后端日志详情"
echo ""
