#!/bin/bash

echo "🚀 Starting Short Drama App - Development Mode"
echo "=============================================="
echo ""

# Check if MySQL is running
if ! pgrep -x "mysqld" > /dev/null; then
    echo "Starting MySQL..."
    brew services start mysql
    sleep 3
fi

# Check if Redis is running
if ! pgrep -x "redis-server" > /dev/null; then
    echo "Starting Redis..."
    brew services start redis
    sleep 2
fi

echo "✅ Database services are running"
echo ""

# Check if database exists
DB_EXISTS=$(mysql -u root -e "SHOW DATABASES LIKE 'short_drama';" 2>/dev/null | grep short_drama)

if [ -z "$DB_EXISTS" ]; then
    echo "⚠️  Database 'short_drama' does not exist!"
    echo "Creating database..."
    mysql -u root -e "CREATE DATABASE short_drama CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Database created"
        echo "Importing schema..."
        mysql -u root short_drama < database/schema.sql 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "✅ Schema imported"
        else
            echo "❌ Failed to import schema. Please run manually:"
            echo "   mysql -u root -p short_drama < database/schema.sql"
        fi
    else
        echo "❌ Failed to create database. Please run manually:"
        echo "   mysql -u root -p"
        echo "   CREATE DATABASE short_drama;"
        echo "   exit"
        echo "   mysql -u root -p short_drama < database/schema.sql"
    fi
else
    echo "✅ Database 'short_drama' already exists"
fi

echo ""
echo "📂 Current directory: $(pwd)"
echo ""

# Check if backend config exists
if [ ! -f "backend/config.yaml" ]; then
    echo "⚠️  Backend config not found, creating from example..."
    cp backend/config.example.yaml backend/config.yaml
    echo "✅ Created backend/config.yaml"
    echo "⚠️  Please edit backend/config.yaml and set your database password!"
    echo ""
fi

# Function to kill background processes on exit
cleanup() {
    echo ""
    echo "🛑 Stopping all services..."
    jobs -p | xargs kill 2>/dev/null
    exit 0
}

trap cleanup INT TERM

echo "🚀 Starting Backend API..."
cd backend
go mod download 2>/dev/null
go run main.go &
BACKEND_PID=$!
cd ..

echo "⏳ Waiting for backend to start..."
sleep 5

echo ""
echo "🚀 Starting Frontend (User App)..."
cd frontend

if [ ! -d "node_modules" ]; then
    echo "📦 Installing frontend dependencies..."
    npm install
fi

if [ ! -f ".env" ]; then
    cp .env.example .env
fi

npm run dev &
FRONTEND_PID=$!
cd ..

sleep 3

echo ""
echo "🚀 Starting Admin Dashboard..."
cd admin

if [ ! -d "node_modules" ]; then
    echo "📦 Installing admin dependencies..."
    npm install
fi

if [ ! -f ".env" ]; then
    cp .env.example .env
fi

npm run dev &
ADMIN_PID=$!
cd ..

echo ""
echo "✅ All services started!"
echo ""
echo "🌐 Access your application:"
echo "   📱 User App:      http://localhost:3000"
echo "   🔧 Backend API:   http://localhost:8080"
echo "   💼 Admin Panel:   http://localhost:3001"
echo ""
echo "👤 Default Admin Login:"
echo "   Email:    admin@example.com"
echo "   Password: admin123"
echo ""
echo "Press Ctrl+C to stop all services"
echo ""

# Wait for all background processes
wait
