#!/bin/bash

echo "🔧 完整修复方案"
echo "=========================="
echo ""

cd /Users/kis/data/cursor_test

echo "1️⃣ 完全删除short_drama数据库..."
docker exec shortdrama-mysql mysql -uroot -prootpassword -e "DROP DATABASE IF EXISTS short_drama;" 2>&1 | grep -v "Warning"

echo "2️⃣ 创建新的数据库..."
docker exec shortdrama-mysql mysql -uroot -prootpassword -e "CREATE DATABASE short_drama CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>&1 | grep -v "Warning"

echo "✅ 数据库已重建"
echo ""

echo "3️⃣ 重新构建后端（应用代码修改）..."
docker-compose build backend 2>&1 | grep -E "Step|Successfully|ERROR" || echo "构建中..."

echo ""
echo "4️⃣ 重启后端..."
docker-compose up -d backend

echo "⏳ 等待后端启动（30秒）..."
SUCCESS=0
for i in {1..30}; do
    sleep 1
    if curl -s http://localhost:9090/health > /dev/null 2>&1; then
        echo ""
        echo "✅ 后端启动成功！"
        SUCCESS=1
        break
    fi
    printf "."
done

if [ $SUCCESS -eq 0 ]; then
    echo ""
    echo "❌ 后端启动超时，查看日志："
    docker logs shortdrama-backend --tail 50
    exit 1
fi

echo ""
echo "5️⃣ 检查表结构..."
echo "所有表："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SHOW TABLES;" 2>&1 | grep -v "Warning"

echo ""
echo "dramas表结构："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "DESCRIBE dramas;" 2>&1 | grep -v "Warning" | head -5

echo ""
echo "6️⃣ 插入管理员账号..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << 'EOSQL' 2>&1 | grep -v "Warning"
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
SELECT '✅ 管理员已创建:' as '', id, email, name, role FROM admin_users;
EOSQL

echo ""
echo "7️⃣ 插入示例数据..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << 'EOSQL' 2>&1 | grep -v "Warning"
INSERT INTO categories (name_en, name_es, name_pt, slug, sort_order, is_active, created_at) VALUES
('Romance', 'Romance', 'Romance', 'romance', 1, 1, NOW()),
('Action', 'Acción', 'Ação', 'action', 2, 1, NOW()),
('Comedy', 'Comedia', 'Comédia', 'comedy', 3, 1, NOW()),
('Drama', 'Drama', 'Drama', 'drama', 4, 1, NOW());
SELECT '✅ 分类已创建:' as '', id, name_en, slug FROM categories;
EOSQL

echo ""
echo "8️⃣ 测试登录..."
RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

if echo "$RESULT" | grep -q "token"; then
    echo "✅ 登录成功！"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 全部完成！系统已就绪！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 访问地址："
    echo "   📱 用户端:     http://localhost"
    echo "   💼 管理后台:   http://localhost:3001"
    echo "   🔧 后端API:    http://localhost:9090"
    echo ""
    echo "👤 管理员登录："
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
    echo ""
    echo "📊 容器状态："
    docker ps --format "   {{.Names}}: {{.Status}}" | grep shortdrama
    echo ""
else
    echo "❌ 登录失败："
    echo "$RESULT"
    echo ""
    echo "查看后端日志："
    docker logs shortdrama-backend --tail 30
fi
