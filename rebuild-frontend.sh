#!/bin/bash

echo "🔨 重新构建前端和管理后台"
echo "=============================="
echo ""

cd /Users/kis/data/cursor_test

echo "🛑 停止旧容器..."
docker stop shortdrama-admin shortdrama-frontend 2>/dev/null
docker rm shortdrama-admin shortdrama-frontend 2>/dev/null

echo "✅ 旧容器已清理"
echo ""

echo "🔨 重新构建镜像..."
docker-compose build admin frontend

if [ $? -eq 0 ]; then
    echo "✅ 镜像构建成功"
    echo ""
    echo "🚀 启动容器..."
    docker-compose up -d admin frontend
    
    echo ""
    echo "⏳ 等待服务启动（5秒）..."
    sleep 5
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ 🎉 前端服务已更新！"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 访问地址："
    echo "   📱 用户端:     http://localhost"
    echo "   💼 管理后台:   http://localhost:3001"
    echo ""
    echo "👤 管理员登录："
    echo "   邮箱: admin@example.com"
    echo "   密码: admin123"
    echo ""
    echo "🔄 请刷新浏览器后再次尝试登录"
    echo ""
else
    echo "❌ 构建失败"
    exit 1
fi
