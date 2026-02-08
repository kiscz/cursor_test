#!/bin/bash

echo "🔍 密码问题诊断"
echo "=========================="
echo ""

echo "1️⃣ 当前数据库中的hash:"
CURRENT_HASH=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT password_hash FROM admin_users WHERE email='admin@example.com';" 2>&1 | grep -v "password_hash" | grep -v "Warning" | tr -d '\n\r')
echo "Hash: $CURRENT_HASH"
echo "长度: ${#CURRENT_HASH}"
echo ""

echo "2️⃣ 测试这个hash是否对应 'admin123'..."

# 创建验证程序
cat > /tmp/verify-hash.go << 'EOF'
package main
import (
    "fmt"
    "os"
    "golang.org/x/crypto/bcrypt"
)
func main() {
    if len(os.Args) < 2 {
        fmt.Println("需要hash参数")
        os.Exit(1)
    }
    hash := os.Args[1]
    password := "admin123"
    
    fmt.Printf("测试hash: %s\n", hash[:40])
    fmt.Printf("密码: %s\n", password)
    
    err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
    if err == nil {
        fmt.Println("结果: ✅ VALID - hash匹配密码")
    } else {
        fmt.Printf("结果: ❌ INVALID - %v\n", err)
    }
}
EOF

echo "使用Go 1.23验证..."
docker run --rm -v /tmp:/work -w /work golang:1.23-alpine sh -c "
apk add --no-cache git > /dev/null 2>&1
go mod init verify > /dev/null 2>&1
go get golang.org/x/crypto/bcrypt > /dev/null 2>&1
go run verify-hash.go '$CURRENT_HASH'
"

echo ""
echo "3️⃣ 生成一个肯定正确的新hash..."

cat > /tmp/gen-new.go << 'EOF'
package main
import (
    "fmt"
    "golang.org/x/crypto/bcrypt"
)
func main() {
    password := "admin123"
    hash, err := bcrypt.GenerateFromPassword([]byte(password), 10)
    if err != nil {
        panic(err)
    }
    
    // 立即验证
    err = bcrypt.CompareHashAndPassword(hash, []byte(password))
    if err == nil {
        fmt.Printf("VERIFIED:%s", string(hash))
    } else {
        fmt.Println("ERROR: 生成的hash验证失败!")
    }
}
EOF

NEW_HASH=$(docker run --rm -v /tmp:/work -w /work golang:1.23-alpine sh -c "
apk add --no-cache git > /dev/null 2>&1
cd /work
go mod init gen > /dev/null 2>&1
go get golang.org/x/crypto/bcrypt > /dev/null 2>&1
go run gen-new.go
" | grep "VERIFIED:" | sed 's/VERIFIED://')

if [ -n "$NEW_HASH" ]; then
    echo "✅ 新hash: ${NEW_HASH:0:40}..."
    echo ""
    
    echo "4️⃣ 更新数据库..."
    docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
    UPDATE admin_users SET password_hash = '$NEW_HASH' WHERE email = 'admin@example.com';
    " 2>&1 | grep -v Warning
    
    echo "✅ 已更新"
    echo ""
    
    echo "5️⃣ 测试登录..."
    sleep 2
    
    RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
        -H "Content-Type: application/json" \
        -d '{"email":"admin@example.com","password":"admin123"}')
    
    if echo "$RESULT" | grep -q "token"; then
        echo "✅ 🎉🎉🎉 成功！"
        echo ""
        echo "$RESULT" | jq . 2>/dev/null
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🎉 问题解决！"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "🌐 管理后台: http://localhost:3001"
        echo "📧 邮箱: admin@example.com"
        echo "🔑 密码: admin123"
        echo ""
        echo "保存工作的hash到文件..."
        echo "$NEW_HASH" > working_hash.txt
        echo "✅ 已保存到 working_hash.txt"
    else
        echo "❌ 还是失败: $RESULT"
        echo ""
        echo "这很奇怪！让我检查后端的CheckPassword函数..."
        docker exec shortdrama-backend cat /app/utils/password.go 2>/dev/null || echo "无法读取password.go"
    fi
else
    echo "❌ 无法生成新hash"
fi

echo ""
