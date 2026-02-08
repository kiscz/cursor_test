#!/bin/bash

echo "🎯 使用后端生成的正确hash修复登录"
echo "===================================="
echo ""

echo "根据诊断日志，后端生成的fresh hash能工作！"
echo "我们需要用后端API生成hash并更新数据库。"
echo ""

echo "1️⃣ 调用后端API生成'admin123'的hash:"
RESPONSE=$(curl -s -X POST http://localhost:9090/api/admin/auth/generate-hash \
    -H "Content-Type: application/json" \
    -d '{"password":"admin123"}')

echo "$RESPONSE"
echo ""

# 提取hash
CORRECT_HASH=$(echo "$RESPONSE" | grep -o '"hash":"[^"]*"' | cut -d'"' -f4)

if [ -z "$CORRECT_HASH" ]; then
    echo "❌ 无法生成hash"
    exit 1
fi

echo "生成的hash: $CORRECT_HASH"
echo "长度: ${#CORRECT_HASH}"
echo ""

echo "2️⃣ 将这个hash插入数据库:"

# 在MySQL容器内创建SQL文件
docker exec shortdrama-mysql sh -c "cat > /tmp/fix_admin.sql << 'SQLEOF'
DELETE FROM admin_users WHERE email = 'admin@example.com';
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at) 
VALUES ('admin@example.com', '$CORRECT_HASH', 'Admin', 'admin', 1, NOW(), NOW());
SELECT 'Inserted:', email, LENGTH(password_hash) as hash_len FROM admin_users WHERE email = 'admin@example.com';
SQLEOF
mysql -uroot -prootpassword short_drama < /tmp/fix_admin.sql
" 2>&1 | grep -v Warning

echo ""

echo "3️⃣ 验证保存的hash:"
SAVED_HASH=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -sN -e "SELECT password_hash FROM admin_users WHERE email='admin@example.com';" 2>/dev/null)
echo "保存的hash: $SAVED_HASH"
echo "长度: ${#SAVED_HASH}"

if [ "$SAVED_HASH" != "$CORRECT_HASH" ]; then
    echo "⚠️  Hash不匹配！可能被截断了"
    echo "原始: $CORRECT_HASH"
    echo "保存: $SAVED_HASH"
fi

echo ""

echo "4️⃣ 测试登录:"
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
    echo "🎉🎉🎉 登录成功！问题已解决！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✅ 登录凭据:"
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
    echo "   管理后台: http://localhost:3001"
    echo ""
    TOKEN=$(echo "$BODY" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "Token: ${TOKEN:0:80}..."
    echo ""
    echo "🎊 恭喜！经过长时间的调试，终于成功了！"
    echo ""
    echo "问题根源: 数据库中的hash不是'admin123'的正确hash"
    echo "解决方案: 使用后端自己生成的hash"
    echo ""
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ 还是失败"
    echo ""
    echo "响应: $BODY"
    echo ""
    echo "查看后端最新日志:"
    docker logs shortdrama-backend 2>&1 | tail -20
fi

echo ""
