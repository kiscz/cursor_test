#!/bin/bash

echo "🧪 直接测试登录"
echo "=========================="
echo ""

echo "1️⃣ 检查后端是否运行..."
if ! curl -s http://localhost:9090/health > /dev/null 2>&1; then
    echo "❌ 后端无响应"
    exit 1
fi
echo "✅ 后端运行中"
echo ""

echo "2️⃣ 检查管理员账号..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
SELECT id, email, name, role, is_active FROM admin_users WHERE email='admin@example.com';
" 2>&1 | grep -v Warning
echo ""

echo "3️⃣ 查看后端最近所有日志（不只是错误）..."
docker logs shortdrama-backend --tail 50 2>&1 | tail -30
echo ""

echo "4️⃣ 发送登录请求（详细输出）..."
echo "请求URL: http://localhost:9090/api/admin/auth/login"
echo "请求体: {\"email\":\"admin@example.com\",\"password\":\"admin123\"}"
echo ""

curl -v -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}' 2>&1

echo ""
echo ""
echo "5️⃣ 立即查看后端日志（看请求是否到达）..."
sleep 1
docker logs shortdrama-backend --tail 5 2>&1

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
