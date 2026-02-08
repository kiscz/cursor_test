#!/bin/bash

echo "🔍 完整系统诊断"
echo "=========================="
echo ""

cd /Users/kis/data/cursor_test

echo "【1】后端容器状态"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker ps --format "{{.Names}}: {{.Status}}" | grep shortdrama
echo ""

echo "【2】后端容器内的配置"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker exec shortdrama-backend cat /root/config.yaml | grep -A 6 "database:"
echo ""

echo "【3】数据库中的admin用户"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << 'EOF'
SELECT 
    id, 
    email, 
    name,
    role,
    is_active,
    SUBSTRING(password_hash, 1, 60) as password_hash
FROM admin_users;
EOF

echo ""
echo "【4】后端日志中的SQL查询"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker logs shortdrama-backend 2>&1 | grep "SELECT.*admin_users" | tail -5
echo ""

echo "【5】测试后端到MySQL的连接"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker exec shortdrama-backend ping -c 2 shortdrama-mysql 2>&1 || echo "无法ping"
echo ""

echo "【6】后端启动日志"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker logs shortdrama-backend 2>&1 | grep -E "Starting|database|connect|migrate" | tail -10
echo ""

echo "【7】手动测试登录"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}' | jq . || echo "无jq"

echo ""
echo "【8】最近的后端错误"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker logs shortdrama-backend 2>&1 | tail -15

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 诊断总结"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 分析问题
CONFIG_HOST=$(docker exec shortdrama-backend cat /root/config.yaml | grep "host:" | head -1 | awk '{print $2}')
ADMIN_COUNT=$(docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT COUNT(*) as c FROM admin_users;" 2>&1 | tail -1)

echo "配置的数据库主机: $CONFIG_HOST"
echo "数据库中的admin数量: $ADMIN_COUNT"
echo ""

if [ "$CONFIG_HOST" != "shortdrama-mysql" ]; then
    echo "❌ 问题：配置文件中数据库主机不正确"
    echo "   应该是: shortdrama-mysql"
    echo "   当前是: $CONFIG_HOST"
    echo ""
    echo "修复方法:"
    echo "  1. 确认 backend/config.yaml 中 database.host 为 shortdrama-mysql"
    echo "  2. 运行: docker restart shortdrama-backend"
elif [ "$ADMIN_COUNT" == "0" ]; then
    echo "❌ 问题：数据库中没有admin用户"
    echo ""
    echo "修复方法:"
    echo "  运行: ./debug-insert.sh"
else
    echo "⚠️  配置和数据看起来都正常，但登录失败"
    echo ""
    echo "可能的原因："
    echo "  1. 密码hash不匹配（最可能）"
    echo "  2. CheckPassword函数有问题"
    echo "  3. 其他逻辑错误"
    echo ""
    echo "建议解决方案："
    echo "  运行: ./try-known-hashes.sh"
    echo "  （尝试多个已知有效的bcrypt hash）"
fi

echo ""
