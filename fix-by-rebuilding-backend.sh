#!/bin/bash

echo "🔧 修复方案：降低bcrypt cost并重建后端"
echo "=========================="
echo ""

cd /Users/kis/data/cursor_test

echo "1️⃣ 后端代码已修改（cost从14改为10）"
echo ""

echo "2️⃣ 重置数据库并使用schema.sql..."
docker exec shortdrama-mysql mysql -uroot -prootpassword -e "DROP DATABASE IF EXISTS short_drama; CREATE DATABASE short_drama;"
docker exec -i shortdrama-mysql mysql -uroot -prootpassword short_drama < database/schema.sql
echo "✅ 数据库已重置"
echo ""

echo "3️⃣ 重建后端..."
docker-compose build backend
docker-compose up -d backend

echo ""
echo "⏳ 等待后端启动（15秒）..."
for i in {1..15}; do
    sleep 1
    if curl -s http://localhost:9090/health > /dev/null 2>&1; then
        echo ""
        echo "✅ 后端启动成功！"
        break
    fi
    printf "."
done
echo ""

echo ""
echo "4️⃣ 检查管理员账号..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT id, email, name, role FROM admin_users;"

echo ""
echo "5️⃣ 测试登录..."
RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

if echo "$RESULT" | grep -q "token"; then
    echo "✅ 登录成功！"
    echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 问题已解决！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 现在可以登录了："
    echo "   访问: http://localhost:3001"
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
else
    echo "❌ 登录失败："
    echo "$RESULT"
    echo ""
    echo "查看后端日志："
    docker logs shortdrama-backend --tail 20
fi

echo ""
