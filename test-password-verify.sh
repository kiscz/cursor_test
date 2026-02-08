#!/bin/bash

echo "🔍 测试密码验证"
echo "=========================="
echo ""

echo "1️⃣ 检查管理员账号和hash..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << 'EOF'
SELECT 
    id, 
    email, 
    name,
    SUBSTRING(password_hash, 1, 60) as full_hash,
    LENGTH(password_hash) as hash_len
FROM admin_users 
WHERE email = 'admin@example.com';
EOF

echo ""
echo "2️⃣ 在Go中测试相同的hash..."

# 创建临时测试程序
cat > /tmp/test-bcrypt.go << 'GOEOF'
package main
import (
    "fmt"
    "golang.org/x/crypto/bcrypt"
)
func main() {
    password := "admin123"
    
    // 测试hash 1 (cost=10, 原始的)
    hash1 := "$2a$10$N9qo8uLOickgx2ZMRZoMye1YHVL98D8jKHMrSMvXGqJHvf5y6b6y2"
    err1 := bcrypt.CompareHashAndPassword([]byte(hash1), []byte(password))
    fmt.Printf("Hash 1 (原始): %v\n", err1 == nil)
    
    // 生成新的hash
    newHash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    fmt.Printf("新生成的hash: %s\n", string(newHash))
    
    // 测试新hash
    err2 := bcrypt.CompareHashAndPassword(newHash, []byte(password))
    fmt.Printf("新hash验证: %v\n", err2 == nil)
}
GOEOF

echo "运行Go测试..."
docker run --rm -v /tmp:/work -w /work golang:1.21-alpine sh -c '
apk add --no-cache git > /dev/null 2>&1
go mod init test > /dev/null 2>&1
go get golang.org/x/crypto/bcrypt > /dev/null 2>&1
go run test-bcrypt.go
' 2>&1 | grep -E "Hash|hash"

echo ""
echo "3️⃣ 使用新生成的hash更新数据库..."

# 生成一个新的hash并插入
NEW_HASH=$(docker run --rm -v /tmp:/work -w /work golang:1.21-alpine sh -c '
cat > gen.go << "EOF2"
package main
import (
    "fmt"
    "golang.org/x/crypto/bcrypt"
)
func main() {
    hash, _ := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
    fmt.Print(string(hash))
}
EOF2
go mod init gen > /dev/null 2>&1
go get golang.org/x/crypto/bcrypt > /dev/null 2>&1
go run gen.go
' 2>&1 | tail -1)

echo "新生成的hash: $NEW_HASH"

if [ -n "$NEW_HASH" ] && [[ "$NEW_HASH" == \$2* ]]; then
    echo "更新数据库..."
    docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
    UPDATE admin_users 
    SET password_hash = '$NEW_HASH' 
    WHERE email = 'admin@example.com';
    "
    
    echo "✅ 已更新"
else
    echo "❌ hash生成失败"
    exit 1
fi

echo ""
echo "4️⃣ 测试登录..."
sleep 2

RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

if echo "$RESULT" | grep -q "token"; then
    echo "✅ 登录成功！"
    echo "$RESULT" | jq . 2>/dev/null
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 问题已解决！"
    echo ""
    echo "🌐 http://localhost:3001"
    echo "📧 admin@example.com"
    echo "🔑 admin123"
else
    echo "❌ 仍然失败: $RESULT"
    echo ""
    echo "后端日志:"
    docker logs shortdrama-backend --tail 5
fi

echo ""
