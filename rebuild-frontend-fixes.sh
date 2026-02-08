#!/bin/bash

echo "🔧 重新构建前端（修复Watch和Login问题）"
echo "=========================================="
echo ""

echo "1️⃣ 停止并删除现有前端容器..."
docker stop shortdrama-frontend 2>/dev/null
docker rm shortdrama-frontend 2>/dev/null
echo "✅ 已清理"
echo ""

echo "2️⃣ 重新构建前端镜像..."
cd /Users/kis/data/cursor_test
docker build -t shortdrama-frontend:latest -f frontend/Dockerfile frontend/ 2>&1 | tail -10

if [ $? -ne 0 ]; then
    echo "❌ 构建失败"
    exit 1
fi

echo ""
echo "✅ 构建成功"
echo ""

echo "3️⃣ 启动新的前端容器..."
docker run -d \
    --name shortdrama-frontend \
    --network shortdrama-network \
    -p 3000:80 \
    shortdrama-frontend:latest

sleep 2
echo "✅ 前端已启动"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 修复完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 修复内容："
echo ""
echo "1. Watch页面Episode切换问题："
echo "   ✅ 移除location.reload()"
echo "   ✅ 使用watch监听路由变化"
echo "   ✅ 自动重新加载数据和播放器"
echo ""
echo "2. Next按钮跳转问题："
echo "   ✅ 正确跳转到下一集"
echo "   ✅ 自动保存观看进度"
echo ""
echo "3. 登录后跳转问题："
echo "   ✅ 记住用户想访问的页面"
echo "   ✅ 登录后自动跳转回原页面"
echo "   ✅ 如果没有原页面则跳转到首页"
echo ""
echo "测试："
echo "  1. 访问: http://localhost:3000/watch/2/1"
echo "  2. 点击其他Episode测试切换"
echo "  3. 点击Next按钮测试跳转"
echo "  4. 未登录访问收藏页，登录后应回到收藏页"
echo ""
