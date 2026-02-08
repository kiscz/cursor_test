#!/bin/bash

echo "👤 插入管理员账号"
echo "=========================="
echo ""

echo "1️⃣ 当前admin_users表内容："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT * FROM admin_users;" 2>&1 | grep -v Warning

echo ""
echo "2️⃣ 插入管理员（邮箱：admin@example.com，密码：admin123）..."

docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << 'EOSQL'
DELETE FROM admin_users WHERE email = 'admin@example.com';

INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at)
VALUES (
    'admin@example.com',
    '$2a$10$N9qo8uLOickgx2ZMRZoMye1YHVL98D8jKHMrSMvXGqJHvf5y6b6y2',
    'Admin',
    'admin',
    1,
    NOW(),
    NOW()
);
EOSQL

echo ""
echo "3️⃣ 验证插入结果："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT id, email, name, role, is_active, created_at FROM admin_users;" 2>&1 | grep -v Warning

echo ""
echo "4️⃣ 测试登录..."
RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

if echo "$RESULT" | grep -q "token"; then
    echo "✅ 登录成功！"
    echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 现在可以登录管理后台了！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 访问: http://localhost:3001"
    echo "📧 邮箱: admin@example.com"
    echo "🔑 密码: admin123"
else
    echo "❌ 登录失败："
    echo "$RESULT"
fi

echo ""
