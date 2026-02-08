#!/bin/bash

echo "🎬 Short Drama App - Quick Start Script"
echo "========================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed!"
    echo "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running!"
    echo "Please start Docker Desktop and try again."
    exit 1
fi

echo "✅ Docker is installed and running"
echo ""

# Check if docker-compose exists
if ! command -v docker-compose &> /dev/null; then
    echo "⚠️  docker-compose not found, using 'docker compose' instead"
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

echo "🔧 Starting services with Docker..."
echo ""

# Stop any existing containers
echo "Stopping existing containers..."
$COMPOSE_CMD down

# Build and start services
echo "Building and starting all services..."
$COMPOSE_CMD up -d --build

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check service status
echo ""
echo "📊 Service Status:"
$COMPOSE_CMD ps

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "🌐 Access your application:"
echo "   📱 User App:      http://localhost:80"
echo "   🔧 Backend API:   http://localhost:8080"
echo "   💼 Admin Panel:   http://localhost:3001"
echo ""
echo "👤 Default Admin Login:"
echo "   Email:    admin@example.com"
echo "   Password: admin123"
echo ""
echo "📝 Useful Commands:"
echo "   View logs:        $COMPOSE_CMD logs -f"
echo "   Stop services:    $COMPOSE_CMD down"
echo "   Restart:          $COMPOSE_CMD restart"
echo ""
echo "🎉 Happy coding!"
