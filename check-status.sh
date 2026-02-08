#!/bin/bash

echo "🔍 检查所有服务状态"
echo "===================="
echo ""

echo "📦 Docker 容器状态："
echo "-------------------"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep shortdrama

echo ""
echo "🔧 后端服务详细信息："
echo "-------------------"

if docker ps | grep -q shortdrama-backend; then
    echo "✅ 后端容器正在运行"
    echo ""
    echo "📋 最近的日志（最后20行）："
    docker logs shortdrama-backend --tail 20 2>&1
    echo ""
    echo "🌐 测试后端健康检查："
    curl -s http://localhost:8080/health || echo "❌ 后端API无响应"
else
    echo "❌ 后端容器未运行"
    echo ""
    echo "查看完整日志："
    docker logs shortdrama-backend 2>&1
fi

echo ""
echo "💡 有用的命令："
echo "  - 查看实时日志: docker logs -f shortdrama-backend"
echo "  - 重启后端: docker restart shortdrama-backend"
echo "  - 进入容器: docker exec -it shortdrama-backend sh"
