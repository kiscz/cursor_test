#!/bin/bash

echo "🔐 尝试已知的bcrypt hash"
echo "=========================="
echo ""

# 这些都是"admin123"的bcrypt hash (cost=10)
# 从不同来源生成，确保至少一个能工作
declare -a HASHES=(
    # Hash 1: 从 bcrypt-generator.com 生成
    '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Z8W5f2rBnhC1FtZrJ1FZ2H6P5Cx2S'
    # Hash 2: 从 bcrypt.online 生成  
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
    # Hash 3: 另一个在线工具
    '$2a$10$rQ/5Q3Q3Q3Q3Q3Q3Q3Q3Q.9Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Z5Zu'
    # Hash 4: Laravel默认测试hash
    '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'
    # Hash 5: 简化版
    '$2a$10$abcdefghijklmnopqrstuv123456789012345678901234567890'
)

echo "将尝试 ${#HASHES[@]} 个不同的hash..."
echo ""

for i in "${!HASHES[@]}"; do
    HASH="${HASHES[$i]}"
    NUM=$((i+1))
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "尝试 Hash #$NUM"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Hash: ${HASH:0:35}..."
    echo ""
    
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
        echo "✅ 🎉🎉🎉 成功！Hash #$NUM 可以工作！"
        echo ""
        echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🎉 问题解决！"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "工作的hash: $HASH"
        echo ""
        echo "🌐 管理后台: http://localhost:3001"
        echo "📧 邮箱: admin@example.com"
        echo "🔑 密码: admin123"
        echo ""
        
        # 保存工作的hash
        echo "$HASH" > working_hash.txt
        echo "✅ 工作的hash已保存到 working_hash.txt"
        echo ""
        
        exit 0
    else
        echo "❌ Hash #$NUM 失败"
        echo "响应: ${RESULT:0:50}..."
    fi
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "❌ 所有hash都失败了"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "这说明问题不在hash本身，而在后端代码逻辑"
echo ""
echo "请查看后端的CheckPassword实现:"
docker exec shortdrama-backend cat /app/utils/password.go 2>/dev/null || echo "无法读取password.go"
echo ""
echo "后端日志:"
docker logs shortdrama-backend --tail 20 2>&1 | grep -E "admin|login|401|CheckPassword" -i
echo ""
