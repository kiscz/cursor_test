#!/bin/bash

echo "🎯 最终解决方案：生成cost=14的hash"
echo "=========================="
echo ""

echo "⏳ 正在生成正确的密码hash（这可能需要1-2分钟，因为cost=14计算量大）..."

# 使用临时Docker容器生成hash
PASSWORD_HASH=$(docker run --rm golang:1.21-alpine sh -c '
apk add --no-cache git > /dev/null 2>&1
cat > /tmp/gen.go << "GOEOF"
package main
import (
    "fmt"
    "golang.org/x/crypto/bcrypt"
)
func main() {
    hash, _ := bcrypt.GenerateFromPassword([]byte("admin123"), 14)
    fmt.Print(string(hash))
}
GOEOF
cd /tmp
go mod init temp > /dev/null 2>&1
go get golang.org/x/crypto/bcrypt > /dev/null 2>&1
go run gen.go
' 2>/dev/null)

if [ -z "$PASSWORD_HASH" ]; then
    echo "❌ 生成失败"
    exit 1
fi

echo "✅ Hash生成成功！"
echo "Hash: ${PASSWORD_HASH:0:40}..."
echo ""

echo "📝 更新数据库..."
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
SELECT id, email, name, role, is_active FROM admin_users;
EOSQL

echo ""
echo "🧪 测试登录..."
sleep 2

RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

echo "$RESULT" | jq . 2>/dev/null

if echo "$RESULT" | grep -q "token"; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ 🎉 登录成功！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 现在可以登录了："
    echo "   访问: http://localhost:3001"
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
else
    echo ""
    echo "❌ 登录仍然失败"
    echo "请检查后端日志: docker logs shortdrama-backend"
fi

echo ""
