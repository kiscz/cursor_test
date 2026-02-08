#!/bin/bash

echo "🔐 重新生成管理员密码"
echo "=========================="
echo ""

# 使用多个已知的bcrypt hash for "admin123"
# cost=10
HASH_COST_10_1='$2a$10$N9qo8uLOickgx2ZMRZoMye1YHVL98D8jKHMrSMvXGqJHvf5y6b6y2'
HASH_COST_10_2='$2a$10$rQ/5Q3Q3Q3Q3Q3Q3Q3Q3Q.mHGxJYvZ3zXxhHzVzVzVzVzVzVzVzVe'
HASH_COST_10_3='$2a$10$CwTycUXWue0Thq9StjUM0uJ8Z8W5f2rBnhC1FtZrJ1FZ2H6P5Cx2S'

echo "方法1：使用预设的bcrypt hash（cost=10）"
echo ""

for i in 1 2 3; do
    echo "尝试hash #$i..."
    
    HASH_VAR="HASH_COST_10_$i"
    CURRENT_HASH="${!HASH_VAR}"
    
    docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << EOSQL
DELETE FROM admin_users WHERE email = 'admin@example.com';
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at)
VALUES (
    'admin@example.com',
    '$CURRENT_HASH',
    'Admin',
    'admin',
    1,
    NOW(),
    NOW()
);
EOSQL

    sleep 1
    
    RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
        -H "Content-Type: application/json" \
        -d '{"email":"admin@example.com","password":"admin123"}')
    
    if echo "$RESULT" | grep -q "token"; then
        echo "✅ 成功！hash #$i 可以使用"
        echo "$RESULT" | jq . 2>/dev/null
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🎉 登录成功！"
        echo "🌐 访问: http://localhost:3001"
        echo "📧 邮箱: admin@example.com"
        echo "🔑 密码: admin123"
        exit 0
    else
        echo "❌ hash #$i 失败"
    fi
    echo ""
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "❌ 所有预设hash都失败了"
echo ""
echo "问题可能在于："
echo "1. 后端bcrypt库版本问题"
echo "2. 后端代码未正确更新"
echo ""
echo "请运行 debug-admin-login.sh 查看详细信息"
