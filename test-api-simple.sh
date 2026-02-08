#!/bin/bash

echo "🧪 简单API测试"
echo ""

# 测试1：后端直接访问
echo "1. 测试后端 (localhost:9090):"
curl -s --max-time 3 http://localhost:9090/api/admin/auth/login \
  -X POST -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' | jq . || echo "请求失败"
echo ""

# 测试2：通过admin nginx代理
echo "2. 测试admin代理 (localhost:3001):"
curl -s --max-time 3 http://localhost:3001/api/admin/auth/login \
  -X POST -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' | jq . || echo "请求失败"
echo ""

echo "如果看到token，说明登录成功！"
