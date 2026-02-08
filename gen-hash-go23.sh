#!/bin/bash

echo "🔐 使用Go 1.23生成bcrypt hash"
echo "=========================="
echo ""

echo "⏳ 生成中（需要1-2分钟，下载Go 1.23镜像）..."
echo ""

# 使用Go 1.23（支持最新的crypto包）
NEW_HASH=$(docker run --rm golang:1.23-alpine sh -c '
apk add --no-cache git > /dev/null 2>&1
mkdir -p /tmp/gen && cd /tmp/gen

cat > main.go << "EOF"
package main
import (
    "fmt"
    "golang.org/x/crypto/bcrypt"
)
func main() {
    hash, err := bcrypt.GenerateFromPassword([]byte("admin123"), 10)
    if err != nil {
        panic(err)
    }
    fmt.Print(string(hash))
}
EOF

go mod init gen > /dev/null 2>&1
go get golang.org/x/crypto/bcrypt > /dev/null 2>&1
go run main.go 2>&1
' | grep '^\$2' | head -1)

if [ -z "$NEW_HASH" ]; then
    echo "❌ 生成失败"
    exit 1
fi

echo "✅ 生成成功: ${NEW_HASH:0:40}..."
echo ""

echo "2️⃣ 更新数据库..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
UPDATE admin_users SET password_hash = '$NEW_HASH' WHERE email = 'admin@example.com';
SELECT id, email, SUBSTRING(password_hash, 1, 40) as hash FROM admin_users WHERE email = 'admin@example.com';
" 2>&1 | grep -v Warning

echo ""
echo "3️⃣ 测试登录..."
sleep 2

RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

echo "响应: $RESULT"
echo ""

if echo "$RESULT" | grep -q "token"; then
    echo "✅ 🎉 成功！"
    echo "$RESULT" | jq . 2>/dev/null
    echo ""
    echo "🌐 http://localhost:3001"
    echo "📧 admin@example.com"
    echo "🔑 admin123"
else
    echo "❌ 失败"
    echo ""
    echo "后端日志:"
    docker logs shortdrama-backend --tail 10
fi

echo ""
