#!/bin/bash

echo "🗑️  重置数据库"
echo "=============="
echo ""

# MySQL连接信息
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_USER="root"
MYSQL_PASS="rootpassword"
MYSQL_DB="short_drama"

echo "⚠️  警告：此操作将删除所有数据库表！"
echo ""
read -p "确认继续？(y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 1
fi

echo "🗃️  删除所有表..."
docker exec -i shortdrama-mysql mysql -u${MYSQL_USER} -p${MYSQL_PASS} ${MYSQL_DB} << 'EOF'
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS watch_histories;
DROP TABLE IF EXISTS ad_rewards;
DROP TABLE IF EXISTS user_favorites;
DROP TABLE IF EXISTS subscriptions;
DROP TABLE IF EXISTS episodes;
DROP TABLE IF EXISTS dramas;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS admin_users;
SET FOREIGN_KEY_CHECKS = 1;
EOF

if [ $? -eq 0 ]; then
    echo "✅ 数据库表已删除"
    echo ""
    echo "📝 重新创建基础数据..."
    
    # 重新运行schema.sql中的基础数据
    docker exec -i shortdrama-mysql mysql -u${MYSQL_USER} -p${MYSQL_PASS} ${MYSQL_DB} << 'EOF'
-- 插入默认分类
INSERT INTO categories (id, name_en, name_es, name_pt, slug, icon, sort_order) VALUES
(1, 'Romance', 'Romance', 'Romance', 'romance', '💕', 1),
(2, 'Action', 'Acción', 'Ação', 'action', '⚔️', 2),
(3, 'Comedy', 'Comedia', 'Comédia', 'comedy', '😂', 3),
(4, 'Drama', 'Drama', 'Drama', 'drama', '🎭', 4),
(5, 'Fantasy', 'Fantasía', 'Fantasia', 'fantasy', '🔮', 5),
(6, 'Thriller', 'Suspense', 'Thriller', 'thriller', '😱', 6)
ON DUPLICATE KEY UPDATE id=id;

-- 插入默认管理员
-- 密码: admin123 (已加密)
INSERT INTO admin_users (email, password_hash, name, role, is_active) VALUES
('admin@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Admin', 'super_admin', TRUE)
ON DUPLICATE KEY UPDATE email=email;
EOF
    
    echo "✅ 基础数据已创建"
    echo ""
    echo "🚀 现在请重新启动后端，GORM会自动创建正确的表结构："
    echo "   docker restart shortdrama-backend"
    echo ""
else
    echo "❌ 删除表失败"
    exit 1
fi
