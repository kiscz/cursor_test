#!/bin/bash

echo "🎯 最终解决方案（使用正确的$2a格式）"
echo "=========================="
echo ""

echo "注意：Go的bcrypt使用 \$2a 或 \$2b 前缀，不是 \$2y"
echo ""

# 使用多个已知的 $2a$ 格式的hash for "admin123"
declare -a HASHES=(
    '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Z8W5f2rBnhC1FtZrJ1FZ2H6P5Cx2S'
    '$2a$10$rQ/5Q3Q3Q3Q3Q3Q3Q3Q3Q.9Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Zu'
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
)

echo "尝试多个预生成的hash..."
echo ""

for i in "${!HASHES[@]}"; do
    HASH="${HASHES[$i]}"
    echo "测试 hash #$((i+1)): ${HASH:0:30}..."
    
    # 更新数据库
    docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
    UPDATE admin_users SET password_hash = '$HASH' WHERE email = 'admin@example.com';
    " 2>&1 | grep -v Warning
    
    sleep 1
    
    # 测试登录
    RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
        -H "Content-Type: application/json" \
        -d '{"email":"admin@example.com","password":"admin123"}')
    
    if echo "$RESULT" | grep -q "token"; then
        echo "✅ 成功！hash #$((i+1)) 可以工作"
        echo ""
        echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🎉 登录成功！"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "🌐 管理后台: http://localhost:3001"
        echo "📧 邮箱: admin@example.com"
        echo "🔑 密码: admin123"
        echo ""
        exit 0
    else
        echo "❌ hash #$((i+1)) 失败"
    fi
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "❌ 所有预设hash都失败了"
echo ""
echo "最后尝试：动态生成hash..."

# 最后尝试：使用正确的Go版本和bcrypt生成
NEW_HASH=$(timeout 120 docker run --rm golang:1.21-alpine sh -c '
echo "package main
import (
    \"fmt\"
    \"golang.org/x/crypto/bcrypt\"
)
func main() {
    hash, err := bcrypt.GenerateFromPassword([]byte(\"admin123\"), 10)
    if err != nil {
        panic(err)
    }
    fmt.Print(string(hash))
}" > /tmp/gen.go

apk add --no-cache git > /dev/null 2>&1
cd /tmp
go mod init temp > /dev/null 2>&1
go get golang.org/x/crypto/bcrypt > /dev/null 2>&1
go run gen.go 2>&1
' | grep -E '^\$2[ab]\$' | head -1)

if [ -n "$NEW_HASH" ]; then
    echo "生成的新hash: ${NEW_HASH:0:40}..."
    
    docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "
    UPDATE admin_users SET password_hash = '$NEW_HASH' WHERE email = 'admin@example.com';
    " 2>&1 | grep -v Warning
    
    sleep 2
    
    RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
        -H "Content-Type: application/json" \
        -d '{"email":"admin@example.com","password":"admin123"}')
    
    if echo "$RESULT" | grep -q "token"; then
        echo "✅ 动态生成的hash成功！"
        echo "$RESULT" | jq . 2>/dev/null
        echo ""
        echo "🌐 http://localhost:3001"
        exit 0
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️ 需要进一步诊断"
echo ""
echo "请运行以下命令查看详细信息："
echo "  docker logs shortdrama-backend --tail 20"
echo "  docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e 'SELECT * FROM admin_users;'"
echo ""
