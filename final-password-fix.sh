#!/bin/bash

echo "🔐 最终密码修复"
echo "=========================="
echo ""

echo "⏳ 生成并验证hash（需要2-3分钟）..."
echo ""

# 在单个Docker命令中完成所有操作
RESULT=$(docker run --rm golang:1.23-alpine sh -c '
echo "安装依赖..."
apk add --no-cache git > /dev/null 2>&1

echo "创建工作目录..."
mkdir -p /app && cd /app

echo "创建Go程序..."
cat > main.go << "GOEOF"
package main
import (
    "fmt"
    "golang.org/x/crypto/bcrypt"
)
func main() {
    password := "admin123"
    
    // 生成hash
    hash, err := bcrypt.GenerateFromPassword([]byte(password), 10)
    if err != nil {
        panic(err)
    }
    
    // 立即验证
    err = bcrypt.CompareHashAndPassword(hash, []byte(password))
    if err == nil {
        fmt.Printf("SUCCESS:%s", string(hash))
    } else {
        fmt.Println("ERROR: 验证失败")
    }
}
GOEOF

echo "初始化Go模块..."
go mod init hashgen > /dev/null 2>&1

echo "下载依赖..."
go get golang.org/x/crypto/bcrypt > /dev/null 2>&1

echo "运行程序..."
go run main.go
')

# 提取hash
NEW_HASH=$(echo "$RESULT" | grep "SUCCESS:" | sed 's/SUCCESS://')

if [ -z "$NEW_HASH" ] || [[ ! "$NEW_HASH" =~ ^\$2 ]]; then
    echo "❌ 生成失败"
    echo "输出: $RESULT"
    exit 1
fi

echo "✅ 成功生成并验证hash！"
echo "Hash: ${NEW_HASH:0:40}..."
echo ""

echo "2️⃣ 更新数据库..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << EOSQL
UPDATE admin_users 
SET password_hash = '$NEW_HASH',
    updated_at = NOW()
WHERE email = 'admin@example.com';

SELECT 
    id, 
    email, 
    name,
    SUBSTRING(password_hash, 1, 35) as hash_preview
FROM admin_users 
WHERE email = 'admin@example.com';
EOSQL

echo ""
echo "3️⃣ 测试登录..."
sleep 3

LOGIN_RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

echo "响应:"
if echo "$LOGIN_RESULT" | grep -q "token"; then
    echo "✅ 🎉🎉🎉 登录成功！"
    echo ""
    echo "$LOGIN_RESULT" | jq . 2>/dev/null || echo "$LOGIN_RESULT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 问题彻底解决！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 访问地址："
    echo "   📱 用户端:     http://localhost"
    echo "   💼 管理后台:   http://localhost:3001"
    echo "   🔧 后端API:    http://localhost:9090"
    echo ""
    echo "👤 管理员登录："
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
    echo ""
    
    # 保存hash
    echo "$NEW_HASH" > working_bcrypt_hash.txt
    echo "✅ 工作的hash已保存到: working_bcrypt_hash.txt"
    echo ""
    
else
    echo "❌ 登录失败: $LOGIN_RESULT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "深度诊断："
    echo ""
    
    echo "1. 后端日志（最近10行）:"
    docker logs shortdrama-backend --tail 10 2>&1 | tail -10
    echo ""
    
    echo "2. 后端的password.go代码:"
    docker exec shortdrama-backend cat /app/utils/password.go 2>/dev/null | head -20 || echo "无法读取"
    echo ""
    
    echo "3. 数据库中的管理员:"
    docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
    SELECT id, email, is_active, LENGTH(password_hash) as hash_len 
    FROM admin_users WHERE email='admin@example.com';
    " 2>&1 | grep -v Warning
fi

echo ""
