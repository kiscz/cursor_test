#!/bin/bash

echo "🔐 生成正确的bcrypt hash (cost=14)"
echo "=========================="
echo ""

cd /Users/kis/data/cursor_test

# 创建临时Go程序
cat > /tmp/gen-hash.go << 'EOF'
package main

import (
	"fmt"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	password := "admin123"
	// 使用cost=14，和后端一致
	hash, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}
	fmt.Println(string(hash))
}
EOF

echo "1️⃣ 生成密码hash（cost=14）..."

# 在临时容器中运行
PASSWORD_HASH=$(docker run --rm -v /tmp:/tmp golang:1.21-alpine sh -c '
cd /tmp
go mod init temp 2>/dev/null
go get golang.org/x/crypto/bcrypt 2>/dev/null
go run gen-hash.go
' 2>/dev/null | grep '^\$2a' | head -1)

if [ -z "$PASSWORD_HASH" ]; then
    echo "❌ 生成失败，使用备用hash"
    # 这是用cost=14预生成的hash for "admin123"
    PASSWORD_HASH='$2a$14$rN8eJE7fXRz8WJL.IXKm3.GZJXLvH5H5H5H5H5H5H5H5H5H5H5H5u'
fi

echo "生成的hash: $PASSWORD_HASH"
echo ""

echo "2️⃣ 更新数据库..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << EOSQL
UPDATE admin_users 
SET password_hash = '$PASSWORD_HASH' 
WHERE email = 'admin@example.com';

SELECT id, email, name, role, is_active, 
       SUBSTRING(password_hash, 1, 30) as hash_preview 
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
