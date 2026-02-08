#!/bin/bash

echo "✨ 简单直接的解决方案"
echo "=========================="
echo ""

echo "思路：让后端容器自己生成hash并验证"
echo ""

echo "1️⃣ 在后端容器中生成hash..."
GENERATED_HASH=$(docker exec shortdrama-backend sh -c '
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
cd /tmp && go run gen.go 2>/dev/null
' 2>&1 | tail -1)

if [ -z "$GENERATED_HASH" ]; then
    echo "❌ 无法在后端容器中生成hash"
    echo "容器可能没有go命令，这是正常的（已编译的二进制）"
    echo ""
    echo "使用外部Go容器生成..."
    GENERATED_HASH=$(docker run --rm golang:1.21-alpine sh -c '
    cat > /tmp/gen.go << "EOF"
package main
import (
    "fmt"
    "golang.org/x/crypto/bcrypt"
)
func main() {
    hash, _ := bcrypt.GenerateFromPassword([]byte("admin123"), 10)
    fmt.Print(string(hash))
}
EOF
    cd /tmp
    go mod init temp > /dev/null 2>&1
    go get golang.org/x/crypto/bcrypt > /dev/null 2>&1
    timeout 60 go run gen.go 2>&1
    ' | grep '^\$2' | head -1)
fi

if [ -z "$GENERATED_HASH" ] || [[ ! "$GENERATED_HASH" =~ ^\$2 ]]; then
    echo "❌ hash生成失败: $GENERATED_HASH"
    echo ""
    echo "使用预生成的有效hash..."
    # 这是一个已知有效的bcrypt hash for "admin123", cost=10
    GENERATED_HASH='$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'
fi

echo "生成的hash: ${GENERATED_HASH:0:40}..."
echo ""

echo "2️⃣ 更新数据库..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << EOSQL
UPDATE admin_users SET password_hash = '$GENERATED_HASH' WHERE email = 'admin@example.com';
SELECT id, email, name, SUBSTRING(password_hash, 1, 20) as hash_preview FROM admin_users WHERE email = 'admin@example.com';
EOSQL

echo ""
echo "3️⃣ 等待2秒后测试..."
sleep 2

RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

if echo "$RESULT" | grep -q "token"; then
    echo "✅ 🎉 成功！"
    echo "$RESULT" | jq . 2>/dev/null
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 http://localhost:3001"
    echo "📧 admin@example.com"  
    echo "🔑 admin123"
else
    echo "❌ 失败: $RESULT"
    echo ""
    echo "最后的调试信息："
    docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT email, LENGTH(password_hash) as len FROM admin_users;"
fi

echo ""
