#!/bin/bash
# 用 API 或 SQL 注册/重置管理员 admin@example.com（密码: admin123）
set -e
cd "$(dirname "$0")"

EMAIL="${1:-admin@example.com}"
PASS="${2:-admin123}"

echo "Registering admin: $EMAIL"

# 优先用 API（需后端已启动且已包含 AdminRegister 接口）
API_RES=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:9090/api/admin/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\",\"name\":\"Admin\"}" 2>/dev/null || true)
HTTP_CODE=$(echo "$API_RES" | tail -n1)
BODY=$(echo "$API_RES" | sed '$d')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
  echo "OK (API): $BODY"
  echo "You can login at http://localhost:3001/login with $EMAIL / $PASS"
  exit 0
fi

# 通过 admin 前端代理再试一次
API_RES=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:3001/api/admin/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\",\"name\":\"Admin\"}" 2>/dev/null || true)
HTTP_CODE=$(echo "$API_RES" | tail -n1)
BODY=$(echo "$API_RES" | sed '$d')
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
  echo "OK (API via :3001): $BODY"
  echo "Login at http://localhost:3001/login with $EMAIL / $PASS"
  exit 0
fi

# API 不可用时：用 Go 生成哈希，再写进 MySQL
echo "API not available, updating database directly..."
HASH=$(docker run --rm -v "$(pwd)/backend:/app" -w /app golang:1.21-alpine sh -c "go run gen-password.go" 2>/dev/null)
if [ -z "$HASH" ]; then
  echo "Failed to generate hash (need Docker and Go image)."
  echo "Option 1: Start backend and rebuild, then run: curl -X POST http://localhost:9090/api/admin/auth/register -H 'Content-Type: application/json' -d '{\"email\":\"$EMAIL\",\"password\":\"$PASS\",\"name\":\"Admin\"}'"
  echo "Option 2: Run in backend dir: go run gen-password.go, then update admin_users.password_hash in MySQL for $EMAIL"
  exit 1
fi

# 用文件拼接 SQL，避免哈希中的 $ 被 shell 展开
TMP=$(mktemp -d)
echo -n "$HASH" > "$TMP/hash"
{
  echo "INSERT INTO admin_users (email, password_hash, name, role, is_active) VALUES ('$EMAIL', '"
  cat "$TMP/hash"
  echo "', 'Admin', 'admin', 1) ON DUPLICATE KEY UPDATE password_hash='"
  cat "$TMP/hash"
  echo "', name='Admin', is_active=1;"
} > "$TMP/run.sql"
docker exec -i shortdrama-mysql mysql -uroot -prootpassword short_drama < "$TMP/run.sql" 2>/dev/null
rm -rf "$TMP"

echo "Admin updated in database. Login at http://localhost:3001/login with $EMAIL / $PASS"
