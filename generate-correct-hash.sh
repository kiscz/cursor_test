#!/bin/bash

echo "🔑 生成并验证正确的bcrypt hash"
echo "=================================="
echo ""

echo "1️⃣ 使用Go生成 'admin123' 的bcrypt hash（cost=10）："

# 在golang容器中生成hash
CORRECT_HASH=$(docker run --rm golang:1.23-alpine sh -c '
mkdir -p /work && cd /work
cat > gen.go << "EOF"
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
go mod init gen >/dev/null 2>&1
go get golang.org/x/crypto/bcrypt >/dev/null 2>&1
go run gen.go
')

echo "生成的hash: $CORRECT_HASH"
echo "长度: ${#CORRECT_HASH}"
echo ""

echo "2️⃣ 验证这个hash能否正确验证 'admin123'："

VERIFY_RESULT=$(docker run --rm golang:1.23-alpine sh -c '
mkdir -p /work && cd /work
cat > verify.go << "EOF"
package main
import (
    "fmt"
    "golang.org/x/crypto/bcrypt"
    "os"
)
func main() {
    err := bcrypt.CompareHashAndPassword([]byte("'"$CORRECT_HASH"'"), []byte("admin123"))
    if err == nil {
        fmt.Print("PASS")
        os.Exit(0)
    } else {
        fmt.Print("FAIL")
        os.Exit(1)
    }
}
EOF
go mod init verify >/dev/null 2>&1
go get golang.org/x/crypto/bcrypt >/dev/null 2>&1
go run verify.go
')

echo "验证结果: $VERIFY_RESULT"
echo ""

if [ "$VERIFY_RESULT" != "PASS" ]; then
    echo "❌ Hash生成失败"
    exit 1
fi

echo "✅ Hash验证通过！"
echo ""

echo "3️⃣ 将正确的hash插入数据库："

# 使用容器内SQL避免shell转义
docker exec shortdrama-mysql sh -c "mysql -uroot -prootpassword short_drama << 'SQLEOF'
DELETE FROM admin_users WHERE email = 'admin@example.com';
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at) 
VALUES ('admin@example.com', '$CORRECT_HASH', 'Admin', 'admin', 1, NOW(), NOW());
SELECT 'Result:', email, LENGTH(password_hash) as len FROM admin_users WHERE email = 'admin@example.com';
SQLEOF
" 2>&1 | grep -v Warning

echo ""

echo "4️⃣ 验证数据库中保存的hash："
SAVED_HASH=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -sN -e "SELECT password_hash FROM admin_users WHERE email='admin@example.com';" 2>/dev/null)
SAVED_LEN=${#SAVED_HASH}

echo "保存后长度: $SAVED_LEN"
echo "保存的hash: ${SAVED_HASH:0:35}...${SAVED_HASH: -10}"
echo ""

if [ "$SAVED_LEN" -ne 60 ]; then
    echo "⚠️  Hash被截断！尝试直接在MySQL容器内操作..."
    
    # 在MySQL容器内部创建文件
    docker exec shortdrama-mysql sh -c "cat > /tmp/insert.sql << 'SQLEOF'
DELETE FROM admin_users WHERE email = 'admin@example.com';
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at) 
VALUES ('admin@example.com', '$CORRECT_HASH', 'Admin', 'admin', 1, NOW(), NOW());
SQLEOF
mysql -uroot -prootpassword short_drama < /tmp/insert.sql
"
    
    SAVED_HASH=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -sN -e "SELECT password_hash FROM admin_users WHERE email='admin@example.com';" 2>/dev/null)
    SAVED_LEN=${#SAVED_HASH}
    echo "重试后长度: $SAVED_LEN"
fi

echo ""
echo "5️⃣ 测试登录："
sleep 2

RESPONSE=$(curl -s -w "\nSTATUS:%{http_code}" -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

STATUS=$(echo "$RESPONSE" | grep "STATUS:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "STATUS:")

echo "HTTP状态: $STATUS"
echo ""

if echo "$BODY" | grep -q "token"; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉🎉🎉 登录成功！！！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✅ 凭据:"
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
    echo "   管理后台: http://localhost:3001"
    echo ""
    TOKEN=$(echo "$BODY" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "Token: ${TOKEN:0:60}..."
    echo ""
    echo "成功使用的hash:"
    echo "$CORRECT_HASH"
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ 登录失败"
    echo ""
    echo "响应: $BODY"
    echo ""
    echo "后端调试日志:"
    docker logs shortdrama-backend 2>&1 | grep "\[DEBUG\]" | tail -10
fi

echo ""
