#!/bin/bash

echo "🔨 重建后端并测试"
echo "=========================="
echo ""

cd /Users/kis/data/cursor_test

echo "1️⃣ 检查源代码中的bcrypt cost..."
echo "backend/utils/password.go:"
grep -A 2 "GenerateFromPassword" backend/utils/password.go
echo ""

echo "2️⃣ 停止旧的后端容器..."
docker stop shortdrama-backend 2>&1 | grep -v Warning
docker rm shortdrama-backend 2>&1 | grep -v Warning
echo "✅ 旧容器已删除"
echo ""

echo "3️⃣ 删除旧镜像（强制重建）..."
docker rmi cursor_test-backend 2>&1 | grep -v Warning || echo "镜像不存在"
echo ""

echo "4️⃣ 重新构建后端（--no-cache）..."
docker-compose build --no-cache backend 2>&1 | tail -20
echo ""

echo "5️⃣ 启动新的后端容器..."
docker-compose up -d backend
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
    echo "❌ 后端启动超时"
    docker logs shortdrama-backend --tail 30
    exit 1
fi

echo ""
echo "6️⃣ 验证后端容器中的代码..."
echo "容器内的password.go:"
docker exec shortdrama-backend cat /app/utils/password.go 2>/dev/null | grep -A 2 "GenerateFromPassword" || echo "无法读取"
echo ""

echo "7️⃣ 验证管理员账号..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
SELECT id, email, name, role, is_active, 
SUBSTRING(password_hash, 1, 7) as hash_type,
LENGTH(password_hash) as hash_length
FROM admin_users WHERE email='admin@example.com';
" 2>&1 | grep -v Warning
echo ""

echo "8️⃣ 测试登录..."
RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

echo "响应:"
echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
echo ""

if echo "$RESULT" | grep -q "token"; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ 🎉 登录成功！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 访问管理后台："
    echo "   http://localhost:3001"
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
    echo ""
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ 登录失败"
    echo ""
    echo "后端日志（最近10行）:"
    docker logs shortdrama-backend --tail 10
    echo ""
    echo "问题排查："
    echo "- 检查第1步和第6步的代码是否一致"
    echo "- 如果不一致，说明Docker缓存问题"
    echo "- 尝试: docker system prune -a --volumes"
fi

echo ""
