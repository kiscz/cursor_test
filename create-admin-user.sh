#!/bin/bash

echo "🔐 创建管理员账号"
echo "=========================="
echo ""

# 检查现有管理员
echo "1️⃣ 检查现有管理员账号..."
docker exec -i shortdrama-mysql mysql -uroot -prootpassword short_drama -e \
  "SELECT id, email, name, role, is_active FROM admin_users;" 2>&1

echo ""
echo "2️⃣ 创建/更新管理员账号..."

# 使用Go的bcrypt包生成密码哈希（密码：admin123）
# bcrypt hash for "admin123"
PASSWORD_HASH='$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'

# 插入或更新管理员账号
docker exec -i shortdrama-mysql mysql -uroot -prootpassword short_drama << EOF
-- 先删除已存在的管理员（如果有）
DELETE FROM admin_users WHERE email = 'admin@example.com';

-- 插入新的管理员账号
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at)
VALUES (
  'admin@example.com',
  '${PASSWORD_HASH}',
  'Admin',
  'admin',
  1,
  NOW(),
  NOW()
);

-- 确认插入结果
SELECT id, email, name, role, is_active FROM admin_users WHERE email = 'admin@example.com';
EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 管理员账号已创建！"
echo ""
echo "📝 登录信息："
echo "   邮箱: admin@example.com"
echo "   密码: admin123"
echo ""
echo "🌐 访问: http://localhost:3001"
echo ""

# 测试登录
echo "🧪 测试登录API..."
curl -X POST http://localhost:9090/api/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' \
  2>&1 | jq . || echo "无法解析JSON"

echo ""
