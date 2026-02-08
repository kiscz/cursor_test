#!/bin/bash

echo "🔧 修复配置并重启"
echo "=========================="
echo ""

echo "✅ 已修改 backend/config.yaml:"
echo "   database.host: host.docker.internal → shortdrama-mysql"
echo "   redis.host: host.docker.internal → shortdrama-redis"
echo ""

echo "1️⃣ 重启后端..."
docker restart shortdrama-backend

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
echo "2️⃣ 查看后端日志（数据库连接）..."
docker logs shortdrama-backend 2>&1 | grep -E "database|connect|migrate|admin_users" -i | tail -15

echo ""
echo "3️⃣ 测试登录..."
sleep 2

RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

if echo "$RESULT" | grep -q "token"; then
    echo "✅ 🎉🎉🎉 登录成功！"
    echo ""
    echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎊 系统部署完成！"
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
else
    echo "❌ 登录失败: $RESULT"
    echo ""
    echo "后端日志（最近20行）:"
    docker logs shortdrama-backend --tail 20
fi

echo ""
