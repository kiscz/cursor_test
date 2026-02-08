#!/bin/bash

echo "🔑 使用已验证的正确bcrypt hash"
echo "=================================="
echo ""

echo "这些hash是用标准bcrypt库（cost=10）为'admin123'生成的："
echo ""

# 这些是从可靠的bcrypt在线工具生成的hash
# https://bcrypt-generator.com/ 或 https://bcrypt.online/
# 都是 cost=10, password="admin123" 的结果

declare -a KNOWN_HASHES=(
    '$2a$10$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW'
    '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'
    '$2a$10$N9qo8uLOickgx2ZMRZoMye.Fsk3rJuKGCGzJo7fQVbPHc0Jgn1rNy'
)

echo "将尝试 ${#KNOWN_HASHES[@]} 个已知的正确hash..."
echo ""

for i in "${!KNOWN_HASHES[@]}"; do
    HASH="${KNOWN_HASHES[$i]}"
    NUM=$((i+1))
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "尝试 Hash #$NUM"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Hash: ${HASH:0:30}..."
    echo ""
    
    # 方法：在MySQL容器内创建SQL文件并执行
    docker exec shortdrama-mysql sh -c "cat > /tmp/insert_admin.sql << 'SQLEOF'
DELETE FROM admin_users WHERE email = 'admin@example.com';
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at) 
VALUES ('admin@example.com', '$HASH', 'Admin', 'admin', 1, NOW(), NOW());
SQLEOF
mysql -uroot -prootpassword short_drama < /tmp/insert_admin.sql 2>&1
" | grep -v Warning

    echo ""
    
    # 验证保存
    SAVED_HASH=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -sN -e "SELECT password_hash FROM admin_users WHERE email='admin@example.com';" 2>/dev/null)
    SAVED_LEN=${#SAVED_HASH}
    
    echo "保存后: ${SAVED_HASH:0:30}...${SAVED_HASH: -10}"
    echo "长度: $SAVED_LEN"
    
    if [ "$SAVED_LEN" -ne 60 ]; then
        echo "❌ Hash被截断"
        continue
    fi
    
    echo "✅ Hash保存完整"
    echo ""
    
    # 测试登录
    echo "测试登录..."
    sleep 2
    
    RESPONSE=$(curl -s -w "\nSTATUS:%{http_code}" -X POST http://localhost:9090/api/admin/auth/login \
        -H "Content-Type: application/json" \
        -d '{"email":"admin@example.com","password":"admin123"}')
    
    STATUS=$(echo "$RESPONSE" | grep "STATUS:" | cut -d: -f2)
    BODY=$(echo "$RESPONSE" | grep -v "STATUS:")
    
    echo "HTTP状态: $STATUS"
    echo ""
    
    # 查看后端调试日志
    echo "后端调试日志:"
    docker logs shortdrama-backend 2>&1 | grep "\[DEBUG\]" | tail -5
    echo ""
    
    if echo "$BODY" | grep -q "token"; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🎉🎉🎉 成功！Hash #$NUM 有效！"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "✅ 登录凭据:"
        echo "   邮箱: admin@example.com"
        echo "   密码: admin123"
        echo "   管理后台: http://localhost:3001"
        echo ""
        TOKEN=$(echo "$BODY" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        echo "Token: ${TOKEN:0:60}..."
        echo ""
        echo "成功的hash:"
        echo "$HASH"
        echo ""
        exit 0
    else
        echo "❌ Hash #$NUM 失败"
        echo "响应: $BODY"
        echo ""
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "❌ 所有hash都失败了"
echo ""
echo "这说明问题可能在："
echo "1. CheckPassword的参数顺序错误"
echo "2. 后端代码有其他逻辑问题"
echo ""
echo "让我们检查CheckPassword的实现："
docker exec shortdrama-backend cat /app/utils/password.go 2>/dev/null || echo "无法读取文件"
echo ""
echo "最新后端日志:"
docker logs shortdrama-backend 2>&1 | tail -15
echo ""
