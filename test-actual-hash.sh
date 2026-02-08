#!/bin/bash

echo "🔍 测试数据库中实际存储的hash"
echo "================================="
echo ""

echo "1️⃣ 读取数据库中的password_hash："
ACTUAL_HASH=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -sN -e "SELECT password_hash FROM admin_users WHERE email='admin@example.com';" 2>/dev/null)

echo "实际Hash: $ACTUAL_HASH"
echo "Hash长度: ${#ACTUAL_HASH}"
echo ""

if [ -z "$ACTUAL_HASH" ]; then
    echo "❌ 无法读取hash，admin记录可能不存在"
    exit 1
fi

echo "2️⃣ 检查hash格式："
if [[ $ACTUAL_HASH == \$2a\$* ]] || [[ $ACTUAL_HASH == \$2b\$* ]] || [[ $ACTUAL_HASH == \$2y\$* ]]; then
    echo "✅ Hash格式正确（bcrypt）"
else
    echo "❌ Hash格式不正确: ${ACTUAL_HASH:0:10}..."
fi

echo ""
echo "3️⃣ 用Go测试这个hash："

# 创建测试程序（修复工作目录问题）
docker run --rm golang:1.23-alpine sh -c '
mkdir -p /work && cd /work
cat > test.go << "GOEOF"
package main

import (
    "fmt"
    "golang.org/x/crypto/bcrypt"
)

func main() {
    hash := "'"$ACTUAL_HASH"'"
    password := "admin123"
    
    fmt.Printf("Testing:\n")
    fmt.Printf("  Password: %s\n", password)
    fmt.Printf("  Hash: %s\n", hash[:20] + "...")
    fmt.Printf("  Hash length: %d\n\n", len(hash))
    
    err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
    if err == nil {
        fmt.Println("✅ 密码验证成功！")
    } else {
        fmt.Printf("❌ 密码验证失败: %v\n", err)
        
        // 尝试生成一个新的正确hash
        fmt.Println("\n生成新的hash:")
        newHash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
        fmt.Printf("  新Hash: %s\n", string(newHash))
    }
}
GOEOF

go mod init test >/dev/null 2>&1
go get golang.org/x/crypto/bcrypt >/dev/null 2>&1
go run test.go
'

echo ""
echo "4️⃣ 检查password_hash字段定义："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
DESCRIBE admin_users;
" 2>&1 | grep -i password

echo ""
echo "5️⃣ 检查是否有其他字段问题："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
SELECT 
    id,
    email,
    LENGTH(password_hash) as hash_len,
    LEFT(password_hash, 10) as hash_start,
    role,
    is_active
FROM admin_users 
WHERE email='admin@example.com';
" 2>&1 | grep -v Warning

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 诊断结果："
echo ""

# 运行Go测试并检查结果
GO_TEST_RESULT=$(docker run --rm golang:1.23-alpine sh -c '
mkdir -p /work && cd /work
cat > test.go << "GOEOF"
package main
import (
    "fmt"
    "golang.org/x/crypto/bcrypt"
)
func main() {
    err := bcrypt.CompareHashAndPassword([]byte("'"$ACTUAL_HASH"'"), []byte("admin123"))
    if err == nil { fmt.Print("SUCCESS") } else { fmt.Print("FAIL") }
}
GOEOF
go mod init test >/dev/null 2>&1 && go get golang.org/x/crypto/bcrypt >/dev/null 2>&1 && go run test.go 2>/dev/null
')

if [ "$GO_TEST_RESULT" = "SUCCESS" ]; then
    echo "✅ Go能正确验证hash"
    echo ""
    echo "🔍 问题可能在于："
    echo "   1. 后端读取的hash与数据库不一致"
    echo "   2. 后端的CheckPassword实现有bug"
    echo "   3. 参数传递顺序错误"
    echo ""
    echo "💡 建议：检查后端日志中的实际hash值"
else
    echo "❌ Go也无法验证这个hash"
    echo ""
    echo "🔍 问题在于数据库中的hash本身："
    echo "   1. Hash可能被截断"
    echo "   2. Hash字段长度不够"
    echo "   3. Hash生成时的密码不是'admin123'"
    echo ""
    echo "💡 建议：重新生成并更新hash"
fi

echo ""
