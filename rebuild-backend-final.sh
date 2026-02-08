#!/bin/bash

echo "🔨 重建后端（应用新配置）"
echo "=========================="
echo ""

cd /Users/kis/data/cursor_test

echo "1️⃣ 停止并删除旧后端..."
docker stop shortdrama-backend
docker rm shortdrama-backend

echo ""
echo "2️⃣ 重新构建后端镜像..."
docker-compose build --no-cache backend

echo ""
echo "3️⃣ 启动新后端..."
docker-compose up -d backend

echo ""
echo "⏳ 等待后端启动（20秒）..."
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
echo ""
echo "4️⃣ 验证配置..."
echo "容器内的config.yaml (database部分):"
docker exec shortdrama-backend cat /root/config.yaml | grep -A 5 "database:"

echo ""
echo "5️⃣ 测试数据库连接..."
echo "从后端容器查询admin_users:"
docker exec shortdrama-backend sh -c '
if command -v mysql > /dev/null; then
    mysql -h shortdrama-mysql -uroot -prootpassword short_drama -e "SELECT COUNT(*) as total FROM admin_users;" 2>&1
else
    echo "MySQL客户端未安装（正常，后端用Go连接）"
fi
' | grep -v Warning

echo ""
echo "6️⃣ 测试登录..."
sleep 3

RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

if echo "$RESULT" | grep -q "token"; then
    echo "✅ 🎉🎉🎉 登录成功！"
    echo ""
    echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎊 问题彻底解决！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 管理后台: http://localhost:3001"
    echo "📧 邮箱: admin@example.com"
    echo "🔑 密码: admin123"
    echo ""
else
    echo "❌ 登录失败: $RESULT"
    echo ""
    echo "后端日志:"
    docker logs shortdrama-backend 2>&1 | grep -E "database|connect|admin|SELECT" -i | tail -20
fi

echo ""
