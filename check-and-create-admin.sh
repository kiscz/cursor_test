#!/bin/bash

echo "🔍 检查并创建管理员账号"
echo "=========================="
echo ""

echo "1️⃣ 当前数据库中的管理员："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT id, email, name, role, is_active FROM admin_users;" 2>/dev/null

echo ""
echo "2️⃣ 创建管理员账号（密码：admin123）..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
DELETE FROM admin_users WHERE email = 'admin@example.com';

INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at)
VALUES (
  'admin@example.com',
  '\$2a\$10\$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
  'Admin',
  'admin',
  1,
  NOW(),
  NOW()
);
" 2>/dev/null

echo ""
echo "3️⃣ 验证创建结果："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT id, email, name, role, is_active, created_at FROM admin_users WHERE email = 'admin@example.com';" 2>/dev/null

echo ""
echo "4️⃣ 测试登录API："
RESPONSE=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}')

if echo "$RESPONSE" | grep -q "token"; then
    echo "✅ 登录成功！"
    echo "$RESPONSE" | jq .
else
    echo "❌ 登录失败："
    echo "$RESPONSE"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 完成！现在可以登录了"
echo ""
echo "🌐 访问: http://localhost:3001"
echo "📧 邮箱: admin@example.com"
echo "🔑 密码: admin123"
echo ""
