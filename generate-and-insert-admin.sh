#!/bin/bash

echo "🔐 生成正确的密码hash并创建管理员"
echo "=========================="
echo ""

cd /Users/kis/data/cursor_test/backend

echo "1️⃣ 生成密码hash（密码：admin123）..."
PASSWORD_HASH=$(docker run --rm -v "$PWD:/app" -w /app golang:1.21-alpine sh -c '
  go mod download golang.org/x/crypto 2>/dev/null
  go run gen-password.go
' 2>/dev/null | tail -1)

echo "生成的hash: $PASSWORD_HASH"
echo ""

echo "2️⃣ 插入到数据库..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << EOSQL
DELETE FROM admin_users WHERE email = 'admin@example.com';
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at)
VALUES (
  'admin@example.com',
  '$PASSWORD_HASH',
  'Admin',
  'admin',
  1,
  NOW(),
  NOW()
);
SELECT id, email, name, role, is_active FROM admin_users WHERE email = 'admin@example.com';
EOSQL

echo ""
echo "3️⃣ 测试登录..."
curl -X POST http://localhost:9090/api/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' \
  2>&1 | head -5

echo ""
echo "✅ 完成！"
