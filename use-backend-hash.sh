#!/bin/bash

echo "🔑 使用后端API生成并测试hash"
echo "=================================="
echo ""

echo "1️⃣ 重新构建后端（包含hash生成API）:"
docker stop shortdrama-backend 2>/dev/null
docker rm shortdrama-backend 2>/dev/null
cd /Users/kis/data/cursor_test
docker build -t shortdrama-backend:latest -f backend/Dockerfile backend/ 2>&1 | tail -5

echo ""
echo "2️⃣ 启动后端:"
docker run -d \
    --name shortdrama-backend \
    --network shortdrama-network \
    -p 9090:9090 \
    -v /Users/kis/data/cursor_test/backend/config.yaml:/root/config.yaml:ro \
    shortdrama-backend:latest

sleep 5
echo "✅ 后端已启动"
echo ""

echo "3️⃣ 调用后端API生成'admin123'的hash:"
RESPONSE=$(curl -s -X POST http://localhost:9090/api/admin/auth/generate-hash \
    -H "Content-Type: application/json" \
    -d '{"password":"admin123"}')

echo "$RESPONSE" | grep -E "password|hash|length"
echo ""

# 提取hash
GENERATED_HASH=$(echo "$RESPONSE" | grep -o '"hash":"[^"]*"' | cut -d'"' -f4)

if [ -z "$GENERATED_HASH" ]; then
    echo "❌ 无法生成hash"
    echo "响应: $RESPONSE"
    exit 1
fi

echo "生成的hash: $GENERATED_HASH"
echo "长度: ${#GENERATED_HASH}"
echo ""

echo "4️⃣ 将hash插入数据库:"
docker exec shortdrama-mysql sh -c "cat > /tmp/insert_admin.sql << 'SQLEOF'
DELETE FROM admin_users WHERE email = 'admin@example.com';
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at) 
VALUES ('admin@example.com', '$GENERATED_HASH', 'Admin', 'admin', 1, NOW(), NOW());
SQLEOF
mysql -uroot -prootpassword short_drama < /tmp/insert_admin.sql 2>&1
" | grep -v Warning

echo "✅ 已插入"
echo ""

echo "5️⃣ 验证数据库:"
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
SELECT 
    email,
    LENGTH(password_hash) as hash_len,
    LEFT(password_hash, 30) as hash_start,
    RIGHT(password_hash, 15) as hash_end
FROM admin_users 
WHERE email = 'admin@example.com';
" 2>&1 | grep -v Warning

echo ""

echo "6️⃣ 测试登录:"
sleep 2

RESPONSE=$(curl -s -w "\nSTATUS:%{http_code}" -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

STATUS=$(echo "$RESPONSE" | grep "STATUS:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "STATUS:")

echo "HTTP状态: $STATUS"
echo ""

if echo "$BODY" | grep -q "token"; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉🎉🎉 登录成功！！！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✅ 凭据:"
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
    echo "   管理后台: http://localhost:3001"
    echo ""
    TOKEN=$(echo "$BODY" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "Token: ${TOKEN:0:60}..."
    echo ""
    echo "🎊 问题已解决！"
    echo ""
    echo "使用的hash: $GENERATED_HASH"
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ 登录失败"
    echo ""
    echo "响应: $BODY"
    echo ""
    echo "后端调试日志:"
    docker logs shortdrama-backend 2>&1 | grep "\[DEBUG" | tail -15
fi

echo ""
