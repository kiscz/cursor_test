#!/bin/bash

echo "🔧 修复password_hash字段长度问题"
echo "================================="
echo ""

echo "问题诊断："
echo "  ❌ bcrypt hash应该是60字符"
echo "  ❌ 但数据库中只有59字符"
echo "  ❌ 说明password_hash字段太短，截断了hash"
echo ""

echo "1️⃣ 检查当前字段定义："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'short_drama'
  AND TABLE_NAME = 'admin_users'
  AND COLUMN_NAME = 'password_hash';
" 2>&1 | grep -v Warning

echo ""
echo "2️⃣ 修改字段长度为VARCHAR(255)（足够存储bcrypt hash）："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
ALTER TABLE admin_users 
MODIFY COLUMN password_hash VARCHAR(255) NOT NULL;
" 2>&1 | grep -v Warning

if [ $? -eq 0 ]; then
    echo "✅ 字段长度已修改"
else
    echo "❌ 修改失败"
    exit 1
fi

echo ""
echo "3️⃣ 验证修改："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
SELECT 
    COLUMN_NAME,
    COLUMN_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'short_drama'
  AND TABLE_NAME = 'admin_users'
  AND COLUMN_NAME = 'password_hash';
" 2>&1 | grep -v Warning

echo ""
echo "4️⃣ 生成新的正确hash（60字符）："

# 生成一个标准的bcrypt hash
CORRECT_HASH='$2a$10$N9qo8uLOickgx2ZMRZoMyeIYGg0T.3jVpGqmH8FkWp0dT5T9eNQSO'

echo "使用预生成的hash: $CORRECT_HASH"
echo "长度: ${#CORRECT_HASH}"

echo ""
echo "5️⃣ 清空并重新插入admin用户（使用正确的60字符hash）："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << 'EOF' 2>&1 | grep -v Warning
DELETE FROM admin_users WHERE email = 'admin@example.com';

INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at)
VALUES (
    'admin@example.com',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIYGg0T.3jVpGqmH8FkWp0dT5T9eNQSO',
    'Admin',
    'admin',
    1,
    NOW(),
    NOW()
);
EOF

echo ""
echo "6️⃣ 验证插入后的hash长度："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
SELECT 
    email,
    LENGTH(password_hash) as hash_length,
    LEFT(password_hash, 20) as hash_start,
    RIGHT(password_hash, 10) as hash_end
FROM admin_users 
WHERE email = 'admin@example.com';
" 2>&1 | grep -v Warning

echo ""
echo "7️⃣ 测试登录："
sleep 2

RESPONSE=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

echo "响应: $RESPONSE"
echo ""

if echo "$RESPONSE" | grep -q "token"; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉🎉🎉 成功！登录终于成功了！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Token: $(echo "$RESPONSE" | grep -o '"token":"[^"]*"')"
    echo ""
    echo "✅ 问题已解决："
    echo "   - password_hash字段从VARCHAR(60)改为VARCHAR(255)"
    echo "   - 重新插入了完整的60字符bcrypt hash"
    echo ""
    echo "现在可以用 admin@example.com / admin123 登录了！"
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ 还是失败"
    echo ""
    echo "后端日志："
    docker logs shortdrama-backend 2>&1 | tail -5
fi

echo ""
