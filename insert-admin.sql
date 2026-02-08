-- 删除已存在的管理员
DELETE FROM admin_users WHERE email = 'admin@example.com';

-- 插入管理员账号
-- 密码: admin123
-- bcrypt hash: $2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at)
VALUES (
  'admin@example.com',
  '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
  'Admin',
  'admin',
  1,
  NOW(),
  NOW()
);

-- 查看结果
SELECT id, email, name, role, is_active FROM admin_users;
