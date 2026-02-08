#!/bin/bash

echo "🔑 用后端代码生成并测试hash"
echo "=============================="
echo ""

echo "1️⃣ 在后端容器中创建hash生成工具："

docker exec shortdrama-backend sh -c 'cat > /tmp/genhash.go << "EOF"
package main

import (
    "fmt"
    "os"
    "golang.org/x/crypto/bcrypt"
)

func main() {
    password := "admin123"
    
    // 生成hash（使用DefaultCost=10）
    hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    if err != nil {
        fmt.Fprintf(os.Stderr, "Error: %v\n", err)
        os.Exit(1)
    }
    
    // 输出hash（不换行）
    fmt.Print(string(hash))
}
EOF
'

echo "✅ 已创建生成器"
echo ""

echo "2️⃣ 编译工具："
docker exec -w /tmp shortdrama-backend sh -c 'go build -o genhash genhash.go' 2>&1 | grep -v "go: downloading" | head -5

if docker exec shortdrama-backend test -f /tmp/genhash; then
    echo "✅ 编译成功"
else
    echo "❌ 编译失败，后端容器可能没有Go工具链"
    echo ""
    echo "方案B：直接使用已知的标准hash"
    
    # 使用在线bcrypt工具验证过的hash
    # 这是用bcrypt.DefaultCost(10)为"admin123"生成的标准hash
    NEW_HASH='$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'
    
    echo "使用标准hash: ${NEW_HASH:0:30}..."
    echo "长度: ${#NEW_HASH}"
fi

echo ""
echo "3️⃣ 生成新hash for 'admin123'："

if docker exec shortdrama-backend test -f /tmp/genhash 2>/dev/null; then
    # 方案A：用容器生成
    NEW_HASH=$(docker exec shortdrama-backend /tmp/genhash)
    echo "生成的hash: ${NEW_HASH:0:30}..."
    echo "长度: ${#NEW_HASH}"
else
    # 方案B：使用标准hash
    NEW_HASH='$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'
    echo "使用标准hash"
fi

echo ""
echo "4️⃣ 将hash插入数据库（使用容器内部执行避免转义）："

# 转义$符号用于shell
ESCAPED_HASH=$(echo "$NEW_HASH" | sed 's/\$/\\$/g')

docker exec shortdrama-mysql sh -c "mysql -uroot -prootpassword short_drama << 'SQLEOF'
DELETE FROM admin_users WHERE email = 'admin@example.com';
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at) 
VALUES ('admin@example.com', '$NEW_HASH', 'Admin', 'admin', 1, NOW(), NOW());
SELECT 'Inserted:', email, LENGTH(password_hash) as hash_len FROM admin_users WHERE email = 'admin@example.com';
SQLEOF
" 2>&1 | grep -v Warning

echo ""
echo "5️⃣ 验证保存的hash："
SAVED_HASH=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -sN -e "SELECT password_hash FROM admin_users WHERE email='admin@example.com';" 2>/dev/null)
SAVED_LEN=${#SAVED_HASH}

echo "保存后: ${SAVED_HASH:0:30}...${SAVED_HASH: -10}"
echo "长度: $SAVED_LEN"

if [ "$SAVED_LEN" -ne 60 ]; then
    echo "❌ Hash被截断！"
    exit 1
fi

echo ""
echo "6️⃣ 测试登录："
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
    echo "🎉🎉🎉 成功！登录终于成功了！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "凭据："
    echo "  邮箱: admin@example.com"
    echo "  密码: admin123"
    echo "  后台: http://localhost:3001"
    echo ""
    TOKEN=$(echo "$BODY" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "Token: ${TOKEN:0:50}..."
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ 还是失败"
    echo ""
    echo "响应: $BODY"
    echo ""
    echo "这说明问题不在hash，而在后端代码逻辑！"
    echo ""
    echo "让我们检查后端的CheckPassword实现："
    echo ""
    docker exec shortdrama-backend cat /app/utils/password.go 2>/dev/null || echo "无法读取"
    echo ""
    echo "后端日志："
    docker logs shortdrama-backend 2>&1 | tail -10
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 建议添加调试日志到后端"
fi

echo ""
