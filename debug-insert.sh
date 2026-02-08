#!/bin/bash

echo "🔍 调试INSERT失败原因"
echo "=========================="
echo ""

echo "1️⃣ 测试基本MySQL连接..."
docker exec shortdrama-mysql mysql -uroot -prootpassword -e "SELECT 'Connection OK' as status;" 2>&1 | grep -v Warning

echo ""
echo "2️⃣ 测试是否能访问short_drama数据库..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT DATABASE();" 2>&1 | grep -v Warning

echo ""
echo "3️⃣ 查看admin_users表结构（完整）..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SHOW CREATE TABLE admin_users\G" 2>&1 | grep -v Warning

echo ""
echo "4️⃣ 尝试最简单的INSERT..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
INSERT INTO admin_users (email, password_hash, name, role, is_active) 
VALUES ('test@test.com', 'hash123', 'Test', 'admin', 1);
SELECT ROW_COUNT() as rows_affected;
SELECT * FROM admin_users WHERE email='test@test.com';
" 2>&1 | grep -v Warning

echo ""
echo "5️⃣ 检查是否有触发器或约束..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
SHOW TRIGGERS;
" 2>&1 | grep -v Warning

echo ""
echo "6️⃣ 尝试用不同方式插入admin@example.com..."

# 方法1：单行SQL
echo "方法1：单行SQL"
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at) VALUES ('admin@example.com', '\$2a\$10\$CwTycUXWue0Thq9StjUM0uJ8Z8W5f2rBnhC1FtZrJ1FZ2H6P5Cx2S', 'Admin', 'admin', 1, NOW(), NOW());" 2>&1

if [ $? -eq 0 ]; then
    echo "✅ 插入命令执行成功"
else
    echo "❌ 插入命令执行失败，错误码: $?"
fi

echo ""
echo "7️⃣ 查看所有admin_users记录..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT * FROM admin_users;" 2>&1 | grep -v Warning

echo ""
echo "8️⃣ 统计记录数..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT COUNT(*) as total FROM admin_users; SELECT COUNT(*) as admin_count FROM admin_users WHERE email='admin@example.com';" 2>&1 | grep -v Warning

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
