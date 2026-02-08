#!/bin/bash

echo "🔧 用PREPARE语句安全插入bcrypt hash"
echo "====================================="
echo ""

echo "问题分析："
echo "  ❌ 60字符的hash保存后变成59字符"
echo "  ❌ 原因：shell中\$符号被转义"
echo "  ✅ 解决：用MySQL PREPARE语句避免shell解释"
echo ""

# 使用真实的bcrypt hash（用单引号保护）
HASH='$2a$10$N9qo8uLOickgx2ZMRZoMyeIYGg0T.3jVpGqmH8FkWp0dT5T9eNQSO'

echo "1️⃣ 使用PREPARE语句插入（避免转义问题）："
echo ""

# 方法1：使用HEREDOC + 单引号
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << 'SQLEOF' 2>&1 | grep -v Warning
-- 删除旧记录
DELETE FROM admin_users WHERE email = 'admin@example.com';

-- 使用PREPARE语句安全插入
SET @email = 'admin@example.com';
SET @hash = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIYGg0T.3jVpGqmH8FkWp0dT5T9eNQSO';
SET @name = 'Admin';
SET @role = 'admin';

PREPARE stmt FROM 'INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at) VALUES (?, ?, ?, ?, 1, NOW(), NOW())';
EXECUTE stmt USING @email, @hash, @name, @role;
DEALLOCATE PREPARE stmt;

-- 验证
SELECT 
    email,
    LENGTH(password_hash) as hash_len,
    password_hash
FROM admin_users 
WHERE email = 'admin@example.com';
SQLEOF

echo ""
echo "2️⃣ 验证hash长度："

SAVED_HASH=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -sN -e "SELECT password_hash FROM admin_users WHERE email='admin@example.com';" 2>/dev/null)
SAVED_LEN=${#SAVED_HASH}

echo "保存的hash: ${SAVED_HASH:0:30}...${SAVED_HASH: -10}"
echo "长度: $SAVED_LEN"
echo ""

if [ "$SAVED_LEN" -ne 60 ]; then
    echo "❌ 还是被截断了！长度 = $SAVED_LEN"
    echo ""
    echo "让我们尝试方法2：直接在MySQL容器内部操作..."
    echo ""
    
    # 方法2：在MySQL容器内部直接执行，避免shell完全参与
    docker exec shortdrama-mysql sh -c "mysql -uroot -prootpassword short_drama -e \"
DELETE FROM admin_users WHERE email = 'admin@example.com';
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at) 
VALUES ('admin@example.com', '\\\$2a\\\$10\\\$N9qo8uLOickgx2ZMRZoMyeIYGg0T.3jVpGqmH8FkWp0dT5T9eNQSO', 'Admin', 'admin', 1, NOW(), NOW());
SELECT email, LENGTH(password_hash) as len FROM admin_users WHERE email = 'admin@example.com';
\"" 2>&1 | grep -v Warning
    
    # 重新检查
    SAVED_HASH=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -sN -e "SELECT password_hash FROM admin_users WHERE email='admin@example.com';" 2>/dev/null)
    SAVED_LEN=${#SAVED_HASH}
    echo ""
    echo "方法2后的长度: $SAVED_LEN"
fi

if [ "$SAVED_LEN" -eq 60 ]; then
    echo "✅ Hash保存成功，长度正确！"
else
    echo "❌ 还是有问题，长度 = $SAVED_LEN"
    echo ""
    echo "方法3：使用base64编码传输..."
    
    # Base64编码hash
    HASH_B64=$(echo -n '$2a$10$N9qo8uLOickgx2ZMRZoMyeIYGg0T.3jVpGqmH8FkWp0dT5T9eNQSO' | base64)
    
    docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << SQLEOF2 2>&1 | grep -v Warning
DELETE FROM admin_users WHERE email = 'admin@example.com';
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at) 
VALUES ('admin@example.com', FROM_BASE64('$HASH_B64'), 'Admin', 'admin', 1, NOW(), NOW());
SELECT email, LENGTH(password_hash) as len FROM admin_users WHERE email = 'admin@example.com';
SQLEOF2

    SAVED_HASH=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -sN -e "SELECT password_hash FROM admin_users WHERE email='admin@example.com';" 2>/dev/null)
    SAVED_LEN=${#SAVED_HASH}
    echo ""
    echo "方法3后的长度: $SAVED_LEN"
fi

echo ""
echo "3️⃣ 最终验证并测试登录："
sleep 2

FINAL_HASH=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -sN -e "SELECT password_hash FROM admin_users WHERE email='admin@example.com';" 2>/dev/null)
FINAL_LEN=${#FINAL_HASH}

echo "最终hash长度: $FINAL_LEN"
echo "最终hash: ${FINAL_HASH:0:40}...${FINAL_HASH: -10}"
echo ""

if [ "$FINAL_LEN" -eq 60 ]; then
    echo "✅ Hash长度正确，测试登录..."
    
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
        echo "🎉🎉🎉 登录成功！！！"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "凭据："
        echo "  邮箱: admin@example.com"
        echo "  密码: admin123"
        echo ""
        echo "访问: http://localhost:3001"
    else
        echo "❌ 登录还是失败"
        echo ""
        echo "后端最新日志："
        docker logs shortdrama-backend 2>&1 | tail -5
    fi
else
    echo "❌ Hash长度还是不对: $FINAL_LEN"
    echo ""
    echo "这可能是MySQL本身的bug或配置问题"
    echo "建议检查MySQL的字符集设置"
fi

echo ""
