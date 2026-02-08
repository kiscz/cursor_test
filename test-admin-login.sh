#!/bin/bash

echo "🧪 测试管理后台登录流程"
echo "=========================="
echo ""

# 测试1：后端健康检查
echo "1️⃣ 测试后端健康检查："
HEALTH=$(curl -s http://localhost:9090/health 2>&1)
if [ $? -eq 0 ]; then
    echo "✅ 后端响应: $HEALTH"
else
    echo "❌ 后端无响应"
    echo "请先启动后端: docker start shortdrama-backend"
    exit 1
fi
echo ""

# 测试2：直接调用后端登录API
echo "2️⃣ 测试后端登录API（直连9090）："
curl -X POST http://localhost:9090/api/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' \
  -w "\nHTTP状态码: %{http_code}\n" \
  2>&1
echo ""

# 测试3：通过管理后台Nginx代理
echo "3️⃣ 测试管理后台代理（通过3001）："
curl -X POST http://localhost:3001/api/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' \
  -w "\nHTTP状态码: %{http_code}\n" \
  2>&1
echo ""

# 测试4：检查admin用户是否存在
echo "4️⃣ 检查数据库中的管理员账号："
docker exec -i shortdrama-mysql mysql -uroot -prootpassword short_drama -e \
  "SELECT id, email, name, role, is_active FROM admin_users;" 2>/dev/null
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 测试完成"
echo ""
echo "如果看到 token 字段，说明登录成功！"
echo "如果返回405，说明Nginx代理配置有问题"
echo "如果返回401，说明账号密码错误"
echo "如果返回500，说明后端或数据库有问题"
echo ""
