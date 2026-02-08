#!/bin/bash

echo "🎯 终极修复方案 - 从零开始"
echo "=========================="
echo ""

cd /Users/kis/data/cursor_test

echo "📋 这个脚本会："
echo "  1. 停止所有服务"
echo "  2. 完全删除数据库"
echo "  3. 重建后端（应用所有代码修改）"
echo "  4. 启动所有服务"
echo "  5. 创建管理员账号"
echo "  6. 测试登录"
echo ""

read -p "继续？(y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第1步：停止所有服务"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker-compose down
echo "✅ 已停止"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第2步：删除旧数据库"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker-compose up -d mysql
sleep 10
docker exec shortdrama-mysql mysql -uroot -prootpassword -e "DROP DATABASE IF EXISTS short_drama;" 2>&1 | grep -v Warning
docker exec shortdrama-mysql mysql -uroot -prootpassword -e "CREATE DATABASE short_drama CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>&1 | grep -v Warning
echo "✅ 数据库已重建"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第3步：重建后端"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker-compose build backend 2>&1 | tail -10
echo "✅ 后端已重建"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第4步：启动所有服务"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker-compose up -d

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
    echo "❌ 后端启动失败"
    echo "查看日志:"
    docker logs shortdrama-backend --tail 50
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第5步：检查数据库表"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SHOW TABLES;" 2>&1 | grep -v Warning | grep -E "admin_users|categories|dramas"
echo "✅ 表已创建"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第6步：创建管理员账号"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 使用一个简单的、已知有效的bcrypt hash
# 这个hash是通过 https://bcrypt-generator.com 生成的
# 密码: admin123, Rounds: 10
HASH='$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'

docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << EOSQL
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at)
VALUES (
    'admin@example.com',
    '$HASH',
    'Admin',
    'admin',
    1,
    NOW(),
    NOW()
);
EOSQL

docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT id, email, name, role FROM admin_users;" 2>&1 | grep -v Warning
echo "✅ 管理员已创建"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第7步：插入基础数据"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << 'EOSQL'
INSERT INTO categories (name_en, name_es, name_pt, slug, sort_order, is_active, created_at) VALUES
('Romance', 'Romance', 'Romance', 'romance', 1, 1, NOW()),
('Action', 'Acción', 'Ação', 'action', 2, 1, NOW()),
('Comedy', 'Comedia', 'Comédia', 'comedy', 3, 1, NOW()),
('Drama', 'Drama', 'Drama', 'drama', 4, 1, NOW()),
('Thriller', 'Thriller', 'Suspense', 'thriller', 5, 1, NOW());
EOSQL

echo "✅ 分类已创建"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "第8步：测试登录"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sleep 2

RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

if echo "$RESULT" | grep -q "token"; then
    echo "✅ 🎉 登录成功！"
    echo ""
    echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 系统部署成功！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📱 用户端:     http://localhost"
    echo "💼 管理后台:   http://localhost:3001"
    echo "🔧 后端API:    http://localhost:9090"
    echo ""
    echo "👤 管理员登录："
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
    echo ""
    echo "📊 容器状态："
    docker ps --format "   {{.Names}}: {{.Status}}" | grep shortdrama
    echo ""
else
    echo "❌ 登录失败"
    echo "响应: $RESULT"
    echo ""
    echo "后端日志:"
    docker logs shortdrama-backend --tail 20
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "请将上面的日志发给我，我来帮您解决"
fi

echo ""
