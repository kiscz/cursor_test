# 🚀 Quick Setup Guide

Get your Short Drama app running in 10 minutes!

---

## Step 1: Install Prerequisites

### macOS
```bash
# Install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required software
brew install node
brew install go
brew install mysql
brew install redis
```

### Windows
- Install Node.js from https://nodejs.org/
- Install Go from https://go.dev/dl/
- Install MySQL from https://dev.mysql.com/downloads/installer/
- Install Redis from https://github.com/tporadowski/redis/releases

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install nodejs npm golang-go mysql-server redis-server
```

---

## Step 2: Setup Database

```bash
# Start MySQL
mysql -u root -p

# Create database
CREATE DATABASE short_drama;
exit;

# Import schema
mysql -u root -p short_drama < database/schema.sql
```

Default admin user will be created:
- **Email**: admin@example.com
- **Password**: admin123

---

## Step 3: Configure Backend

```bash
cd backend

# Copy config
cp config.example.yaml config.yaml

# Edit config.yaml and update:
# - database.password (your MySQL password)
# - jwt.secret (change in production!)
# - stripe keys (if testing payments)

# Install Go dependencies
go mod download

# Run backend
go run main.go
```

Backend runs at: **http://localhost:8080**

---

## Step 4: Setup Frontend (User App)

Open a new terminal:

```bash
cd frontend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Run frontend
npm run dev
```

Frontend runs at: **http://localhost:3000**

---

## Step 5: Setup Admin Dashboard

Open a new terminal:

```bash
cd admin

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Run admin
npm run dev
```

Admin dashboard runs at: **http://localhost:3001**

---

## Step 6: Test the System

### User App (http://localhost:3000)
1. Browse dramas (no login needed)
2. Click "Register" to create account
3. Browse and add favorites
4. Click on a drama → Episodes
5. Watch video (test player)

### Admin Dashboard (http://localhost:3001)
1. Login with:
   - Email: **admin@example.com**
   - Password: **admin123**
2. Go to "Dramas"
3. Click "Add Drama" to create content
4. Add episodes to your drama

---

## Step 7: Add Sample Data (Optional)

### Quick Test Drama

In Admin Dashboard:
1. Login
2. Go to "Dramas" → "Add Drama"
3. Fill in:
   - Title: "Test Drama"
   - Description: "A test drama series"
   - Category: Romance
   - Poster URL: `https://via.placeholder.com/300x450`
   - Status: Published
   - Featured: Yes
   - Free Episodes: 3
4. Save
5. Go to Episodes
6. Add Episode 1:
   - Episode #: 1
   - Title: "Pilot"
   - Video URL: Use any test video URL or local file
   - Duration: 120 seconds
   - Free: Yes
7. Add more episodes

Now refresh the user app and see your drama!

---

## Step 8: Build Android APK (Optional)

### Prerequisites
- Android Studio installed
- Java JDK 11+

```bash
cd frontend

# Build production version
npm run build

# Add Android platform (first time only)
npx cap add android

# Sync files
npx cap sync

# Open in Android Studio
npx cap open android
```

In Android Studio:
1. Wait for Gradle sync
2. Build → Generate Signed Bundle/APK
3. Select APK
4. Create keystore (first time)
5. Build and get your APK!

---

## Common Issues & Solutions

### Backend won't start
```bash
# Check if MySQL is running
brew services list  # macOS
sudo service mysql status  # Linux

# Check if port 8080 is free
lsof -i :8080  # macOS/Linux
netstat -ano | findstr :8080  # Windows
```

### Frontend errors
```bash
# Clear node_modules and reinstall
rm -rf node_modules
npm install

# Clear cache
npm cache clean --force
```

### Database connection error
- Check MySQL is running
- Verify password in `backend/config.yaml`
- Check database name is `short_drama`

### Redis connection error (optional)
- Redis is optional for now
- Start Redis: `brew services start redis` (macOS)
- Or comment out Redis in code temporarily

---

## Next Steps

### For Development
1. Read API documentation in code
2. Customize UI/UX in frontend
3. Add more dramas via admin panel
4. Test payment flow (needs Stripe account)

### For Production
1. Read `DEPLOYMENT.md` for full deployment guide
2. Set up SSL/HTTPS
3. Configure AWS S3 for video storage
4. Set up Stripe for real payments
5. Add Google AdMob for ads
6. Deploy to cloud (AWS, DigitalOcean, etc.)

---

## Project Structure

```
short-drama-app/
├── frontend/          # User app (Vue 3 + Vant)
├── backend/           # Go API server
├── admin/             # Admin dashboard (Vue 3 + Element Plus)
├── database/          # SQL schema
├── README.md          # Project overview
├── DEPLOYMENT.md      # Production deployment guide
└── FEATURES.md        # Complete feature list
```

---

## Support

### Documentation
- README.md - Project overview
- DEPLOYMENT.md - Production setup
- FEATURES.md - Complete feature list

### Default Credentials
- **Admin**: admin@example.com / admin123
- **Test User**: Create via registration

---

## Quick Commands Reference

```bash
# Backend
cd backend && go run main.go

# Frontend
cd frontend && npm run dev

# Admin
cd admin && npm run dev

# Database
mysql -u root -p short_drama < database/schema.sql

# Build APK
cd frontend && npm run build && npx cap sync && npx cap open android
```

---

**You're all set! 🎉**

Start building your short drama streaming platform!
