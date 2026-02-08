#!/bin/bash

echo "🔍 完整诊断管理员登录问题"
echo "=========================="
echo ""

echo "1️⃣ 检查admin_users表是否存在："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SHOW TABLES LIKE 'admin_users';" 2>&1 | grep -v Warning

echo ""
echo "2️⃣ 查看admin_users表结构："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "DESCRIBE admin_users;" 2>&1 | grep -v Warning

echo ""
echo "3️⃣ 查看所有管理员账号："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT id, email, name, role, is_active, LEFT(password_hash, 30) as hash_preview FROM admin_users;" 2>&1 | grep -v Warning

echo ""
echo "4️⃣ 统计admin_users记录数："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT COUNT(*) as total FROM admin_users;" 2>&1 | grep -v Warning

echo ""
echo "5️⃣ 后端日志（最近20行）："
docker logs shortdrama-backend --tail 20 2>&1 | grep -E "admin|login|401|error" -i

echo ""
echo "6️⃣ 检查后端代码中的bcrypt cost："
docker exec shortdrama-backend cat /app/utils/password.go 2>/dev/null | grep -A 2 "HashPassword"

echo ""
echo "7️⃣ 测试登录（详细）："
curl -v -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}' 2>&1 | tail -15

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 诊断完成"
echo ""
