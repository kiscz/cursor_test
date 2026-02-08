#!/bin/bash

echo "🔍 检查后端数据库连接"
echo "=========================="
echo ""

echo "1️⃣ 后端配置文件..."
cat backend/config.yaml | grep -A 5 "database:"
echo ""

echo "2️⃣ 从后端容器内查看数据库..."
echo "后端能看到的admin_users:"
docker exec shortdrama-backend sh -c '
apk add --no-cache mysql-client > /dev/null 2>&1
mysql -h host.docker.internal -uroot -prootpassword short_drama -e "SELECT COUNT(*) as cnt FROM admin_users;" 2>&1
' 2>&1 | grep -v Warning || echo "无法从后端连接MySQL"

echo ""
echo "3️⃣ 检查Docker网络..."
echo "后端容器的网络:"
docker inspect shortdrama-backend --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'

echo "MySQL容器的网络:"
docker inspect shortdrama-mysql --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'

echo ""
echo "4️⃣ 从后端容器ping MySQL..."
docker exec shortdrama-backend ping -c 2 host.docker.internal 2>&1 || echo "无法ping"

echo ""
echo "5️⃣ 重启后端并观察连接..."
echo "重启后端..."
docker restart shortdrama-backend

sleep 10

echo "查看启动日志（数据库连接）:"
docker logs shortdrama-backend 2>&1 | grep -E "database|mysql|connect|error|admin_users" -i | tail -20

echo ""
echo "6️⃣ 再次测试登录..."
sleep 2

RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

if echo "$RESULT" | grep -q "token"; then
    echo "✅ 成功！"
    echo "$RESULT" | jq .
else
    echo "❌ 失败: $RESULT"
    echo ""
    echo "后端日志:"
    docker logs shortdrama-backend --tail 5
fi

echo ""
