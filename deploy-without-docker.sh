#!/bin/bash

echo "🚀 Short Drama App - 简易部署方案（不使用Docker）"
echo "================================================"
echo ""
echo "这个脚本会使用简化的方式启动应用，无需完整的MySQL和Redis"
echo ""

# 检查Node.js
if ! command -v node &> /dev/null; then
    echo "❌ 未找到Node.js"
    echo "请先安装Node.js 18+: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js 版本: $(node --version)"

# 检查Go
if ! command -v go &> /dev/null; then
    echo "❌ 未找到Go"
    echo "请先安装Go 1.21+: https://go.dev/dl/"
    exit 1
fi

echo "✅ Go 版本: $(go version)"
echo ""

# 创建简化的后端配置
echo "📝 创建简化配置..."
cat > backend/config.yaml << 'EOF'
server:
  port: 8080
  mode: debug

database:
  host: localhost
  port: 3306
  user: root
  password: ""
  dbname: short_drama
  max_idle_conns: 10
  max_open_conns: 100

redis:
  host: localhost
  port: 6379
  password: ""
  db: 0

jwt:
  secret: demo_secret_key_change_in_production
  expires_hours: 720

stripe:
  secret_key: sk_test_demo
  webhook_secret: whsec_demo
  price_monthly: price_demo
  price_yearly: price_demo

aws:
  region: us-east-1
  access_key_id: demo
  secret_access_key: demo
  s3_bucket: demo
  cloudfront_domain: ""

admob:
  app_id: ca-app-pub-demo
  rewarded_ad_unit_id: ca-app-pub-demo

cors:
  allowed_origins:
    - http://localhost:3000
    - http://localhost:5173
  allow_credentials: true
EOF

echo "✅ 配置文件已创建"
echo ""

# 创建前端环境变量
cat > frontend/.env << 'EOF'
VITE_API_BASE_URL=http://localhost:8080/api
EOF

cat > admin/.env << 'EOF'
VITE_API_BASE_URL=http://localhost:8080/api
EOF

echo "✅ 环境变量已配置"
echo ""

# 安装依赖
echo "📦 安装前端依赖..."
cd frontend
npm install --silent
cd ..

echo "📦 安装管理后台依赖..."
cd admin
npm install --silent
cd ..

echo "📦 安装Go依赖..."
cd backend
go mod download
cd ..

echo ""
echo "✅ 所有依赖安装完成"
echo ""

# 提示数据库设置
echo "⚠️  注意：此部署方案需要MySQL数据库"
echo ""
echo "如果你已经有MySQL，请运行："
echo "  mysql -u root -p short_drama < database/schema.sql"
echo ""
echo "如果没有MySQL，可以："
echo "1. 安装MySQL: brew install mysql"
echo "2. 启动MySQL: brew services start mysql"
echo "3. 创建数据库并导入schema"
echo ""
echo "如果暂时不想设置MySQL，后端API会启动失败，但前端可以正常浏览"
echo ""

read -p "按Enter继续启动服务..."

# 启动函数
cleanup() {
    echo ""
    echo "🛑 停止所有服务..."
    kill $(jobs -p) 2>/dev/null
    exit 0
}

trap cleanup INT TERM

# 启动后端
echo ""
echo "🚀 启动后端API (可能因数据库未配置而失败)..."
cd backend
go run main.go > ../logs/backend.log 2>&1 &
BACKEND_PID=$!
cd ..

sleep 3

# 启动前端
echo "🚀 启动前端用户App..."
cd frontend
npm run dev > ../logs/frontend.log 2>&1 &
FRONTEND_PID=$!
cd ..

sleep 3

# 启动管理后台
echo "🚀 启动管理后台..."
cd admin
npm run dev > ../logs/admin.log 2>&1 &
ADMIN_PID=$!
cd ..

echo ""
echo "✅ 服务启动完成！"
echo ""
echo "🌐 访问地址："
echo "   📱 用户App:    http://localhost:3000"
echo "   🔧 后端API:    http://localhost:8080"
echo "   💼 管理后台:   http://localhost:3001"
echo ""
echo "📝 默认管理员："
echo "   邮箱: admin@example.com"
echo "   密码: admin123"
echo ""
echo "💡 提示："
echo "   - 日志文件在 logs/ 目录"
echo "   - 按 Ctrl+C 停止所有服务"
echo "   - 如果后端API失败，检查MySQL是否配置"
echo ""

# 等待
wait
