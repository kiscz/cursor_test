#!/bin/bash

echo "🔍 用后端容器测试密码验证"
echo "================================="
echo ""

echo "1️⃣ 读取数据库中的hash："
ACTUAL_HASH=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -sN -e "SELECT password_hash FROM admin_users WHERE email='admin@example.com';" 2>/dev/null)

echo "Hash: $ACTUAL_HASH"
echo "长度: ${#ACTUAL_HASH}"
echo ""

if [ -z "$ACTUAL_HASH" ]; then
    echo "❌ 无法读取hash"
    exit 1
fi

echo "2️⃣ 创建测试程序在后端容器中："
docker exec shortdrama-backend sh -c 'cat > /tmp/test-hash.go << "EOF"
package main

import (
    "fmt"
    "os"
    "golang.org/x/crypto/bcrypt"
)

func main() {
    if len(os.Args) < 3 {
        fmt.Println("Usage: test-hash <password> <hash>")
        os.Exit(1)
    }
    
    password := os.Args[1]
    hash := os.Args[2]
    
    fmt.Printf("测试:\n")
    fmt.Printf("  密码: %s\n", password)
    fmt.Printf("  Hash前20字符: %s...\n", hash[:20])
    fmt.Printf("  Hash长度: %d\n\n", len(hash))
    
    err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
    if err == nil {
        fmt.Println("✅ SUCCESS")
        os.Exit(0)
    } else {
        fmt.Printf("❌ FAIL: %v\n\n", err)
        
        // 生成正确的hash
        fmt.Println("生成新hash:")
        newHash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
        fmt.Printf("%s\n", string(newHash))
        os.Exit(1)
    }
}
EOF
'

echo "3️⃣ 编译测试程序："
docker exec -w /tmp shortdrama-backend sh -c 'go build -o test-hash test-hash.go' 2>&1 | grep -v "go: downloading"

echo ""
echo "4️⃣ 运行测试："
TEST_RESULT=$(docker exec shortdrama-backend /tmp/test-hash "admin123" "$ACTUAL_HASH" 2>&1)

echo "$TEST_RESULT"
echo ""

if echo "$TEST_RESULT" | grep -q "✅ SUCCESS"; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ 数据库中的hash是正确的！"
    echo ""
    echo "问题一定在后端代码逻辑中！"
    echo ""
    echo "让我们检查后端实际执行的代码..."
    echo ""
    
    echo "5️⃣ 检查CheckPassword函数："
    docker exec shortdrama-backend cat /app/utils/password.go 2>/dev/null || echo "无法读取password.go"
    
    echo ""
    echo "6️⃣ 添加调试日志到后端："
    cat > /tmp/test-admin-with-debug.sh << 'DEBUGEOF'
#!/bin/bash
echo "测试登录（查看详细日志）："
docker logs shortdrama-backend 2>&1 | tail -5
curl -v -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}' 2>&1
echo ""
echo "后端日志："
docker logs shortdrama-backend 2>&1 | tail -10
DEBUGEOF
    chmod +x /tmp/test-admin-with-debug.sh
    
    echo "💡 下一步："
    echo "   1. 修改backend/handlers/admin.go添加调试日志"
    echo "   2. 或者运行: /tmp/test-admin-with-debug.sh"
    
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ 数据库中的hash本身有问题！"
    echo ""
    
    # 提取新生成的hash
    NEW_HASH=$(echo "$TEST_RESULT" | grep '^\$2[aby]\$' | tail -1)
    
    if [ -n "$NEW_HASH" ]; then
        echo "💡 我已生成新的正确hash:"
        echo "   $NEW_HASH"
        echo ""
        echo "现在更新数据库..."
        
        docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
        UPDATE admin_users 
        SET password_hash = '$NEW_HASH'
        WHERE email = 'admin@example.com';
        " 2>&1 | grep -v Warning
        
        echo ""
        echo "✅ 已更新！现在测试登录："
        sleep 1
        
        RESPONSE=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
            -H "Content-Type: application/json" \
            -d '{"email":"admin@example.com","password":"admin123"}')
        
        if echo "$RESPONSE" | grep -q "token"; then
            echo "🎉🎉🎉 登录成功！！！"
            echo "$RESPONSE" | grep -o '"token":"[^"]*"'
        else
            echo "还是失败: $RESPONSE"
        fi
    fi
fi

echo ""
