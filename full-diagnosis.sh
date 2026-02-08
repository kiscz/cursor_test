#!/bin/bash

echo "🔍 完整诊断"
echo "=========================="
echo ""

echo "1️⃣ 检查数据库表："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SHOW TABLES;" 2>&1 | head -20

echo ""
echo "2️⃣ 检查admin_users表结构："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "DESCRIBE admin_users;" 2>&1

echo ""
echo "3️⃣ 查询所有管理员："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT * FROM admin_users;" 2>&1

echo ""
echo "4️⃣ 尝试插入管理员："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << 'EOSQL'
DELETE FROM admin_users WHERE email = 'admin@example.com';
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at)
VALUES (
  'admin@example.com',
  '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
  'Admin',
  'admin',
  1,
  NOW(),
  NOW()
);
SELECT 'Inserted:', id, email, name, role, is_active FROM admin_users WHERE email = 'admin@example.com';
EOSQL

echo ""
echo "5️⃣ 后端日志（最近30行）："
docker logs shortdrama-backend --tail 30 2>&1

echo ""
echo "6️⃣ 测试登录（直接到后端9090）："
curl -v -X POST http://localhost:9090/api/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' 2>&1 | tail -20

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
