#!/bin/bash

echo "📦 Installing Dependencies for Short Drama App"
echo "=============================================="
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew is already installed"
fi

echo ""
echo "📥 Installing required software..."
echo ""

# Update Homebrew
brew update

# Install Node.js
echo "Installing Node.js 18..."
brew install node@18
brew link --overwrite node@18

# Install Go
echo "Installing Go 1.21..."
brew install go

# Install MySQL
echo "Installing MySQL 8..."
brew install mysql

# Install Redis
echo "Installing Redis..."
brew install redis

echo ""
echo "✅ All dependencies installed!"
echo ""
echo "🔧 Starting services..."
echo ""

# Start MySQL
echo "Starting MySQL..."
brew services start mysql

# Start Redis
echo "Starting Redis..."
brew services start redis

echo ""
echo "⏳ Waiting for services to start..."
sleep 5

echo ""
echo "✅ Services started!"
echo ""
echo "📝 Next Steps:"
echo "1. Set MySQL root password:"
echo "   mysql_secure_installation"
echo ""
echo "2. Create database:"
echo "   mysql -u root -p < database/schema.sql"
echo ""
echo "3. Configure backend:"
echo "   cd backend"
echo "   cp config.example.yaml config.yaml"
echo "   # Edit config.yaml with your settings"
echo ""
echo "4. Run setup-dev.sh to start all services"
echo ""
