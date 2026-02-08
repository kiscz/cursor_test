#!/bin/bash

echo "🔄 重启后端"
echo "=========================="
echo ""

echo "1️⃣ 检查容器状态..."
docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep shortdrama
echo ""

echo "2️⃣ 查看后端日志（看看为什么停止）..."
docker logs shortdrama-backend --tail 30 2>&1 | tail -20
echo ""

echo "3️⃣ 重启后端..."
docker restart shortdrama-backend

echo ""
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
    echo ""
    echo "查看错误日志:"
    docker logs shortdrama-backend --tail 50
    exit 1
fi

echo ""
echo "4️⃣ 测试健康检查..."
curl -s http://localhost:9090/health | jq . || curl -s http://localhost:9090/health
echo ""

echo ""
echo "5️⃣ 测试管理员登录..."
RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

echo "响应: $RESULT"
echo ""

if echo "$RESULT" | grep -q "token"; then
    echo "✅ 🎉 登录成功！"
    echo "$RESULT" | jq . 2>/dev/null
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 后端已恢复！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 管理后台: http://localhost:3001"
    echo "📧 邮箱: admin@example.com"
    echo "🔑 密码: admin123"
    echo ""
else
    echo "❌ 登录失败: $RESULT"
    echo ""
    echo "问题可能是密码hash不对"
    echo "运行以下命令生成新hash:"
    echo "  ./gen-hash-go23.sh"
fi

echo ""
