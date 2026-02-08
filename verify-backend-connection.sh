#!/bin/bash

echo "🔍 验证后端连接的数据库"
echo "=========================="
echo ""

echo "1️⃣ 我们看到的数据库（从MySQL容器）："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
SELECT 'FROM MYSQL CONTAINER:' as source;
SELECT id, email, name, role FROM admin_users;
" 2>&1 | grep -v Warning

echo ""
echo "2️⃣ 后端日志中的查询："
docker logs shortdrama-backend 2>&1 | grep "SELECT.*admin_users.*email" | tail -3

echo ""
echo "3️⃣ 测试：在数据库中插入特殊标记，看后端能否看到"
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at) 
VALUES ('test_backend_can_see_me@test.com', 'hash', 'TEST_MARKER', 'admin', 1, NOW());
" 2>&1 | grep -v Warning

sleep 2

echo ""
echo "4️⃣ 尝试用测试邮箱登录（会失败，但能看到后端查询）："
curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test_backend_can_see_me@test.com","password":"test"}' > /dev/null

sleep 1

echo ""
echo "5️⃣ 查看后端最新日志："
docker logs shortdrama-backend 2>&1 | tail -5

echo ""
echo "6️⃣ 验证数据库中的记录："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
SELECT COUNT(*) as total, GROUP_CONCAT(email) as emails FROM admin_users;
" 2>&1 | grep -v Warning

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "分析："
echo ""

# 检查后端日志中是否有"record not found"
if docker logs shortdrama-backend 2>&1 | tail -10 | grep -q "record not found"; then
    echo "❌ 后端查询返回空结果"
    echo ""
    echo "可能的原因："
    echo "  1. 后端连接到了错误的数据库"
    echo "  2. 后端使用了不同的表名"
    echo "  3. WHERE条件有问题（大小写/空格）"
    echo ""
    echo "让我们检查后端实际连接的数据库..."
    docker exec shortdrama-backend cat /root/config.yaml | grep -A 6 "database:"
else
    echo "✅ 后端能查询到数据"
    echo "问题可能在密码验证逻辑"
fi

echo ""
