#!/bin/bash

echo "🔧 完整修复：数据库 + 管理员账号"
echo "=========================="
echo ""

cd /Users/kis/data/cursor_test

echo "1️⃣ 完全删除并重建数据库..."
docker exec shortdrama-mysql mysql -uroot -prootpassword << 'EOSQL'
DROP DATABASE IF EXISTS short_drama;
CREATE DATABASE short_drama CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOSQL

echo "✅ 数据库已重建"
echo ""

echo "2️⃣ 重启后端（让GORM自动创建表）..."
docker restart shortdrama-backend

echo "⏳ 等待后端启动和表创建（20秒）..."
for i in {1..20}; do
    sleep 1
    if curl -s http://localhost:9090/health > /dev/null 2>&1; then
        echo ""
        echo "✅ 后端启动成功！"
        break
    fi
    printf "."
done
echo ""

sleep 3

echo ""
echo "3️⃣ 检查表是否创建..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SHOW TABLES;"

echo ""
echo "4️⃣ 插入管理员账号（密码：admin123，cost=10）..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << 'EOSQL'
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

SELECT id, email, name, role, is_active FROM admin_users;
EOSQL

echo ""
echo "5️⃣ 插入示例分类..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << 'EOSQL'
INSERT INTO categories (name_en, name_es, name_pt, slug, sort_order, created_at, updated_at) VALUES
('Romance', 'Romance', 'Romance', 'romance', 1, NOW(), NOW()),
('Action', 'Acción', 'Ação', 'action', 2, NOW(), NOW()),
('Comedy', 'Comedia', 'Comédia', 'comedy', 3, NOW(), NOW()),
('Drama', 'Drama', 'Drama', 'drama', 4, NOW(), NOW()),
('Thriller', 'Thriller', 'Suspense', 'thriller', 5, NOW(), NOW());

SELECT id, name_en, slug FROM categories;
EOSQL

echo ""
echo "6️⃣ 测试登录..."
RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

if echo "$RESULT" | grep -q "token"; then
    echo "✅ 登录成功！"
    echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 全部完成！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 现在可以登录管理后台了："
    echo "   访问: http://localhost:3001"
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
    echo ""
    echo "📱 用户端访问："
    echo "   访问: http://localhost"
    echo ""
else
    echo "❌ 登录失败："
    echo "$RESULT"
    echo ""
    echo "查看后端日志："
    docker logs shortdrama-backend --tail 30
fi

echo ""
