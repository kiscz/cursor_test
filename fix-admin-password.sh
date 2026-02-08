#!/bin/bash

echo "🔐 修复管理员密码"
echo "=========================="
echo ""

echo "1️⃣ 在后端容器中生成正确的密码hash..."
PASSWORD_HASH=$(docker exec shortdrama-backend sh -c '
cat > /tmp/gen.go << "EOF"
package main
import (
    "fmt"
    "golang.org/x/crypto/bcrypt"
)
func main() {
    hash, _ := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
    fmt.Print(string(hash))
}
EOF
cd /tmp && go run gen.go
')

echo "生成的hash: $PASSWORD_HASH"
echo ""

echo "2️⃣ 更新数据库..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << EOSQL
UPDATE admin_users SET password_hash = '$PASSWORD_HASH' WHERE email = 'admin@example.com';
SELECT id, email, name, role, is_active, 
       LEFT(password_hash, 20) as password_preview 
FROM admin_users WHERE email = 'admin@example.com';
EOSQL

echo ""
echo "3️⃣ 测试登录..."
RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}')

if echo "$RESULT" | grep -q "token"; then
    echo "✅ 登录成功！"
    echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
else
    echo "❌ 登录失败："
    echo "$RESULT"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 访问: http://localhost:3001"
echo "📧 邮箱: admin@example.com"
echo "🔑 密码: admin123"
echo ""
