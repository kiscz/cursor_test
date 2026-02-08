#!/bin/bash

echo "🎯 使用已验证的working hash"
echo "============================"
echo ""

# 这是后端刚才生成并验证成功的hash
WORKING_HASH='$2a$10$jQEKEMf6Yb2DD4F26ey7heXwBsDd3gOAms.qFq25vfT8cnRry67gi'

echo "使用诊断日志中验证成功的hash:"
echo "$WORKING_HASH"
echo ""

echo "1️⃣ 更新数据库:"

docker exec shortdrama-mysql sh -c "cat > /tmp/fix_admin.sql << 'SQLEOF'
DELETE FROM admin_users WHERE email = 'admin@example.com';
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at) 
VALUES ('admin@example.com', '$WORKING_HASH', 'Admin', 'admin', 1, NOW(), NOW());
SQLEOF
mysql -uroot -prootpassword short_drama < /tmp/fix_admin.sql
" 2>&1 | grep -v Warning

echo "✅ 已更新"
echo ""

echo "2️⃣ 验证保存:"
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
SELECT email, LENGTH(password_hash) as len, password_hash 
FROM admin_users 
WHERE email = 'admin@example.com';
" 2>&1 | grep -v Warning

echo ""

echo "3️⃣ 测试登录:"
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
    echo "🎉🎉🎉 成功！登录终于成功了！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✅ 凭据:"
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
    echo "   管理后台: http://localhost:3001"
    echo ""
    TOKEN=$(echo "$BODY" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "Token: ${TOKEN:0:80}..."
    echo ""
    echo "🎊 问题解决！"
    echo ""
    echo "根本原因: 数据库中的hash不是'admin123'的正确hash"
    echo "解决方案: 使用后端生成并验证过的working hash"
    echo ""
else
    echo "❌ 失败"
    echo "响应: $BODY"
    echo ""
    echo "后端日志:"
    docker logs shortdrama-backend 2>&1 | grep "\[DEBUG" | tail -10
fi

echo ""
