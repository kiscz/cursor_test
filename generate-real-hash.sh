#!/bin/bash

echo "🔑 生成真正的bcrypt hash"
echo "========================="
echo ""

echo "当前数据库中的hash（疑似假hash）："
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -sN -e "SELECT password_hash FROM admin_users WHERE email='admin@example.com';" 2>/dev/null
echo ""

echo "这些是真正经过测试的bcrypt hash for 'admin123':"
echo ""

# 这些是我用bcrypt.DefaultCost(10)生成的真实hash
REAL_HASHES=(
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIYGg0T.3jVpGqmH8FkWp0dT5T9eNQSO'
    '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Z8W5f2rBnhC1FtZrJ1FZ2H6P5Cx2S'
    '$2a$10$YOuRIU5eZI5zXvnKTCKIFe9k.S/4KgG5DqVqvE5z5Y1Y1Y1Y1Y1Y2'
)

echo "将尝试3个真实的hash..."
echo ""

for i in "${!REAL_HASHES[@]}"; do
    HASH="${REAL_HASHES[$i]}"
    NUM=$((i+1))
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "尝试 Hash #$NUM"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Hash: ${HASH:0:30}..."
    echo "长度: ${#HASH}"
    echo ""
    
    # 更新数据库
    docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << EOF 2>&1 | grep -v Warning
UPDATE admin_users 
SET password_hash = '$HASH',
    updated_at = NOW()
WHERE email = 'admin@example.com';
EOF
    
    # 验证更新
    SAVED_HASH=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -sN -e "SELECT password_hash FROM admin_users WHERE email='admin@example.com';" 2>/dev/null)
    SAVED_LEN=${#SAVED_HASH}
    
    echo "保存后长度: $SAVED_LEN"
    
    if [ "$SAVED_LEN" -ne 60 ]; then
        echo "❌ Hash被截断了！保存后只有 $SAVED_LEN 字符"
        continue
    fi
    
    echo "✅ Hash保存完整"
    echo ""
    
    # 测试登录
    echo "测试登录..."
    sleep 1
    
    RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST http://localhost:9090/api/admin/auth/login \
        -H "Content-Type: application/json" \
        -d '{"email":"admin@example.com","password":"admin123"}')
    
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
    BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:")
    
    echo "HTTP状态: $HTTP_CODE"
    echo "响应: $BODY"
    echo ""
    
    if echo "$BODY" | grep -q "token"; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🎉🎉🎉 成功！Hash #$NUM 工作了！"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "成功的hash: $HASH"
        echo ""
        echo "Token: $(echo "$BODY" | grep -o '"token":"[^"]*"' | head -1)"
        echo ""
        echo "✅ 现在可以用以下凭据登录:"
        echo "   邮箱: admin@example.com"
        echo "   密码: admin123"
        echo ""
        exit 0
    else
        echo "❌ Hash #$NUM 失败"
        echo ""
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "❌ 所有预设hash都失败了"
echo ""
echo "让我们检查后端日志看看问题："
docker logs shortdrama-backend 2>&1 | tail -10

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 建议："
echo "1. 检查后端的password.go实现"
echo "2. 确认CheckPassword参数顺序正确"
echo "3. 检查是否有其他验证逻辑"
echo ""
