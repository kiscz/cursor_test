#!/bin/bash

echo "👤 确保管理员账号存在"
echo "=========================="
echo ""

echo "1️⃣ 检查admin_users表是否存在..."
TABLE_EXISTS=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SHOW TABLES LIKE 'admin_users';" 2>&1 | grep -c "admin_users")

if [ "$TABLE_EXISTS" -eq 0 ]; then
    echo "❌ admin_users表不存在！"
    echo "重启后端让GORM创建表..."
    docker restart shortdrama-backend
    sleep 10
else
    echo "✅ admin_users表存在"
fi

echo ""
echo "2️⃣ 查看表结构..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "DESCRIBE admin_users;" 2>&1 | grep -v Warning

echo ""
echo "3️⃣ 查看当前所有管理员..."
ADMIN_COUNT=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT COUNT(*) as cnt FROM admin_users;" 2>&1 | grep -v "cnt" | grep -v "Warning" | tr -d '\n\r ')
echo "当前管理员数量: $ADMIN_COUNT"

if [ "$ADMIN_COUNT" != "0" ]; then
    docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT id, email, name, role, is_active FROM admin_users;" 2>&1 | grep -v Warning
fi

echo ""
echo "4️⃣ 删除所有旧数据（避免冲突）..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "DELETE FROM admin_users;" 2>&1 | grep -v Warning
echo "✅ 已清空"

echo ""
echo "5️⃣ 插入管理员（直接SQL）..."

# 使用简单的SQL，不依赖变量
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << 'EOSQL'
INSERT INTO admin_users 
    (email, password_hash, name, role, is_active, created_at, updated_at) 
VALUES 
    (
        'admin@example.com',
        '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
        'Admin',
        'admin',
        1,
        NOW(),
        NOW()
    );
EOSQL

if [ $? -ne 0 ]; then
    echo "❌ 插入失败！"
    exit 1
fi

echo "✅ 插入完成"
echo ""

echo "6️⃣ 验证插入结果..."
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << 'EOSQL'
SELECT 
    id,
    email,
    name,
    role,
    is_active,
    SUBSTRING(password_hash, 1, 40) as hash_preview,
    created_at
FROM admin_users 
WHERE email = 'admin@example.com';
EOSQL

echo ""
FINAL_COUNT=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT COUNT(*) as cnt FROM admin_users WHERE email='admin@example.com';" 2>&1 | grep -v "cnt" | grep -v "Warning" | tr -d '\n\r ')
echo "admin@example.com 记录数: $FINAL_COUNT"

if [ "$FINAL_COUNT" == "1" ]; then
    echo "✅ 管理员账号存在"
    echo ""
    
    echo "7️⃣ 测试登录..."
    sleep 2
    
    RESULT=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
        -H "Content-Type: application/json" \
        -d '{"email":"admin@example.com","password":"admin123"}')
    
    if echo "$RESULT" | grep -q "token"; then
        echo "✅ 🎉 登录成功！"
        echo ""
        echo "$RESULT" | jq . 2>/dev/null || echo "$RESULT"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🎉 问题解决！"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "🌐 管理后台: http://localhost:3001"
        echo "📧 邮箱: admin@example.com"
        echo "🔑 密码: admin123"
    else
        echo "❌ 登录失败: $RESULT"
        echo ""
        echo "账号存在但登录失败，说明是密码hash问题"
        echo "运行以下命令尝试不同的hash:"
        echo "  ./try-known-hashes.sh"
    fi
else
    echo "❌ 插入失败，记录数: $FINAL_COUNT"
    echo ""
    echo "检查MySQL错误日志:"
    docker logs shortdrama-mysql --tail 20
fi

echo ""
