#!/bin/bash

echo "🗑️  完全重置数据库"
echo "==================="
echo ""

# MySQL连接信息
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_USER="root"
MYSQL_PASS="rootpassword"
MYSQL_DB="short_drama"

echo "⚠️  警告：此操作将删除并重建整个数据库！"
echo ""
read -p "确认继续？(y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 1
fi

echo "🗃️  删除并重建数据库..."
docker exec -i shortdrama-mysql mysql -u${MYSQL_USER} -p${MYSQL_PASS} << 'EOF'
DROP DATABASE IF EXISTS short_drama;
CREATE DATABASE short_drama CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOF

if [ $? -eq 0 ]; then
    echo "✅ 数据库已重建"
    echo ""
    echo "🚀 重启后端，GORM will自动创建所有表..."
    docker restart shortdrama-backend
    echo ""
    echo "⏳ 等待后端启动（30秒）..."
    sleep 30
    echo ""
    
    # 测试连接
    echo "🧪 测试后端..."
    if curl -s http://localhost:9090/health > /dev/null 2>&1; then
        echo "✅ 后端启动成功！"
        echo ""
        
        # 插入基础数据
        echo "📝 插入基础数据..."
        docker exec -i shortdrama-mysql mysql -u${MYSQL_USER} -p${MYSQL_PASS} ${MYSQL_DB} << 'EOFDATA'
-- 插入分类
INSERT INTO categories (name_en, name_es, name_pt, slug, icon, sort_order) VALUES
('Romance', 'Romance', 'Romance', 'romance', '💕', 1),
('Action', 'Acción', 'Ação', 'action', '⚔️', 2),
('Comedy', 'Comedia', 'Comédia', 'comedy', '😂', 3),
('Drama', 'Drama', 'Drama', 'drama', '🎭', 4),
('Fantasy', 'Fantasía', 'Fantasia', 'fantasy', '🔮', 5),
('Thriller', 'Suspense', 'Thriller', 'thriller', '😱', 6)
ON DUPLICATE KEY UPDATE id=id;

-- 插入管理员（密码: admin123）
INSERT INTO admin_users (email, password_hash, name, role, is_active) VALUES
('admin@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Admin', 'super_admin', TRUE)
ON DUPLICATE KEY UPDATE email=email;
EOFDATA
        
        echo "✅ 基础数据已创建"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "✅ 🎉 数据库设置完成！"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "🌐 访问地址："
        echo "   📱 用户端:     http://localhost"
        echo "   💼 管理后台:   http://localhost:3001"
        echo "   🔧 后端API:    http://localhost:9090"
        echo ""
        echo "👤 管理员登录："
        echo "   邮箱: admin@example.com"
        echo "   密码: admin123"
        echo ""
    else
        echo "⚠️  后端未能成功启动"
        echo "查看日志: docker logs -f shortdrama-backend"
    fi
else
    echo "❌ 数据库重建失败"
    exit 1
fi
