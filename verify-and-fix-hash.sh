#!/bin/bash

echo "🔍 验证并修复hash"
echo "=========================="
echo ""

echo "1️⃣ 验证当前数据库中的hash..."
CURRENT_HASH='$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'

# 创建验证程序
cat > /tmp/verify.go << 'EOF'
package main
import (
    "fmt"
    "os"
    "golang.org/x/crypto/bcrypt"
)
func main() {
    if len(os.Args) < 3 {
        fmt.Println("Usage: verify <hash> <password>")
        os.Exit(1)
    }
    hash := os.Args[1]
    password := os.Args[2]
    
    err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
    if err == nil {
        fmt.Println("VALID")
    } else {
        fmt.Println("INVALID:", err)
    }
}
EOF

echo "验证hash是否对应'admin123'..."
VERIFY_RESULT=$(timeout 60 docker run --rm -v /tmp:/work -w /work golang:1.21-alpine sh -c "
apk add --no-cache git > /dev/null 2>&1
go mod init verify > /dev/null 2>&1
go get golang.org/x/crypto/bcrypt > /dev/null 2>&1
go run verify.go '$CURRENT_HASH' 'admin123' 2>&1
" | tail -1)

echo "结果: $VERIFY_RESULT"

if [[ "$VERIFY_RESULT" == "VALID" ]]; then
    echo "✅ hash是正确的！"
    echo ""
    echo "❓ 问题可能在后端代码或逻辑"
    echo ""
    echo "让我检查后端是否正确调用CheckPassword..."
    
else
    echo "❌ hash不正确！需要重新生成"
    echo ""
    echo "2️⃣ 生成新的hash..."
    
    cat > /tmp/generate.go << 'EOF'
package main
import (
    "fmt"
    "golang.org/x/crypto/bcrypt"
)
func main() {
    // 生成3个hash
    for i := 0; i < 3; i++ {
        hash, err := bcrypt.GenerateFromPassword([]byte("admin123"), 10)
        if err != nil {
            panic(err)
        }
        fmt.Println(string(hash))
    }
}
EOF
    
    echo "生成3个新hash..."
    NEW_HASHES=$(timeout 90 docker run --rm -v /tmp:/work -w /work golang:1.21-alpine sh -c "
    apk add --no-cache git > /dev/null 2>&1
    cd /work
    go mod init gen > /dev/null 2>&1
    go get golang.org/x/crypto/bcrypt > /dev/null 2>&1
    go run generate.go 2>&1
    " | grep '^\$2')
    
    if [ -z "$NEW_HASHES" ]; then
        echo "❌ 生成失败"
        exit 1
    fi
    
    echo "生成的hash:"
    echo "$NEW_HASHES"
    echo ""
    
    # 使用第一个hash
    NEW_HASH=$(echo "$NEW_HASHES" | head -1)
    
    echo "3️⃣ 更新数据库..."
    docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
    UPDATE admin_users SET password_hash = '$NEW_HASH' WHERE email = 'admin@example.com';
    " 2>&1 | grep -v Warning
    
    echo "✅ 已更新"
fi

echo ""
echo "4️⃣ 最终测试..."
sleep 2

RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

if echo "$RESULT" | grep -q "token"; then
    echo "✅ 🎉 成功！"
    echo "$RESULT" | jq . 2>/dev/null
    echo ""
    echo "🌐 http://localhost:3001"
    echo "📧 admin@example.com"
    echo "🔑 admin123"
else
    echo "❌ 仍然失败: $RESULT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 深度诊断"
    echo ""
    echo "检查admin.go中的CheckPassword调用..."
    docker exec shortdrama-backend cat /app/handlers/admin.go 2>/dev/null | grep -A 3 "CheckPassword" || echo "无法读取"
    echo ""
    echo "后端最近日志:"
    docker logs shortdrama-backend --tail 10 2>&1 | tail -10
fi

echo ""
