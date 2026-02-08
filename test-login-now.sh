#!/bin/bash

echo "🧪 立即测试登录"
echo "=========================="
echo ""

echo "1️⃣ 确认管理员存在..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
SELECT id, email, name, role, is_active FROM admin_users WHERE email='admin@example.com';
" 2>&1 | grep -v Warning

echo ""
echo "2️⃣ 检查后端是否运行..."
if curl -s http://localhost:9090/health > /dev/null 2>&1; then
    echo "✅ 后端运行中"
else
    echo "❌ 后端未运行"
    exit 1
fi

echo ""
echo "3️⃣ 测试登录（详细输出）..."
curl -v -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}' 2>&1 | tail -20

echo ""
echo ""
echo "4️⃣ 测试登录（解析JSON）..."
RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

echo "响应: $RESULT"
echo ""

if echo "$RESULT" | grep -q "token"; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ 🎉🎉🎉 登录成功！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
    echo ""
    echo "🌐 管理后台: http://localhost:3001"
    echo "📧 邮箱: admin@example.com"
    echo "🔑 密码: admin123"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎊 系统部署完成！现在可以开始使用了！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo "❌ 登录失败: $RESULT"
    echo ""
    echo "查看后端日志:"
    docker logs shortdrama-backend --tail 10
fi

echo ""
