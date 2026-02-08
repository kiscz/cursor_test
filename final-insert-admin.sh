#!/bin/bash

echo "🔐 最终插入管理员账号"
echo "=========================="
echo ""

echo "1️⃣ 连接测试："
if ! docker exec shortdrama-mysql mysql -uroot -prootpassword -e "SELECT 1;" 2>&1 | grep -q "1"; then
    echo "❌ 无法连接MySQL"
    exit 1
fi
echo "✅ MySQL连接正常"
echo ""

echo "2️⃣ 检查数据库和表："
docker exec shortdrama-mysql mysql -uroot -prootpassword -e "USE short_drama; SHOW TABLES LIKE 'admin_users';" 2>&1 | grep -v Warning
echo ""

echo "3️⃣ 清空admin_users表："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "TRUNCATE TABLE admin_users;" 2>&1 | grep -v Warning
echo "✅ 表已清空"
echo ""

echo "4️⃣ 插入管理员（使用最简单的SQL）："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
INSERT INTO admin_users 
(email, password_hash, name, role, is_active, created_at, updated_at) 
VALUES 
('admin@example.com', '\$2a\$10\$N9qo8uLOickgx2ZMRZoMye1YHVL98D8jKHMrSMvXGqJHvf5y6b6y2', 'Admin', 'admin', 1, NOW(), NOW());
" 2>&1 | grep -v Warning

echo ""
echo "5️⃣ 验证插入（直接查询）："
ADMIN_COUNT=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT COUNT(*) as cnt FROM admin_users WHERE email='admin@example.com';" 2>&1 | grep -v Warning | tail -1)
echo "admin@example.com 记录数: $ADMIN_COUNT"

if [ "$ADMIN_COUNT" != "1" ]; then
    echo "❌ 插入失败！"
    exit 1
fi
echo "✅ 插入成功！"
echo ""

echo "6️⃣ 查看管理员详情："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
SELECT 
    id, 
    email, 
    name, 
    role, 
    is_active,
    SUBSTRING(password_hash, 1, 30) as hash_start
FROM admin_users 
WHERE email='admin@example.com';
" 2>&1 | grep -v Warning
echo ""

echo "7️⃣ 等待3秒后测试登录..."
sleep 3

RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

echo "登录响应:"
echo "$RESULT"
echo ""

if echo "$RESULT" | grep -q "token"; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ 🎉 登录成功！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 现在可以登录管理后台了："
    echo "   访问: http://localhost:3001"
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
    echo ""
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ 登录仍然失败"
    echo ""
    echo "后端日志："
    docker logs shortdrama-backend --tail 10 2>&1 | grep -E "admin|401|error" -i
    echo ""
    echo "可能的原因："
    echo "1. 密码hash与后端bcrypt cost不匹配"
    echo "2. 后端代码未正确更新"
    echo ""
    echo "建议：重新构建后端"
    echo "docker-compose build --no-cache backend && docker-compose up -d backend"
fi

echo ""
