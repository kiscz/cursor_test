# 🎬 Short Drama App - Global Edition

> A complete, production-ready short-form drama streaming platform for international markets

[![Status](https://img.shields.io/badge/status-production--ready-brightgreen)]()
[![Go](https://img.shields.io/badge/Go-1.21+-00ADD8?logo=go)]()
[![Vue](https://img.shields.io/badge/Vue-3.x-4FC08D?logo=vue.js)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()

**📱 Mobile App (H5 + Android) • 🔧 Go Backend API • 💼 Admin Dashboard • 🌍 Multi-language**

## 🎬 Features

### User App (H5 + Android APK)
- 📱 Browse & discover short dramas (1-3 min episodes)
- 🎥 Video player with smooth playback
- ⭐ Follow/bookmark favorite series
- 📺 Watch history & continue watching
- 🎁 Rewarded video ads (unlock episodes)
- 👑 Premium membership (ad-free + early access)
- 🌍 Multi-language support (EN/ES/PT)
- 🔐 User authentication

### Admin Dashboard
- 📊 Content management (upload, edit, organize)
- 👥 User & membership management
- 💰 Revenue & analytics dashboard
- 🎯 Ad configuration
- 📈 Statistics & reports

### Backend API
- 🚀 RESTful API (Go + Gin)
- 🔒 JWT authentication
- 💳 Stripe payment integration
- 📦 AWS S3 video storage
- 🎯 Google AdMob integration
- 💾 MySQL + Redis caching

## 📦 Tech Stack

### Frontend (User App)
- **Framework**: Vue 3 + Vite
- **UI Library**: Vant 4 (mobile)
- **Video Player**: Video.js
- **Package to APK**: Capacitor
- **State**: Pinia
- **HTTP**: Axios
- **i18n**: vue-i18n

### Backend
- **Language**: Go 1.21+
- **Framework**: Gin
- **Database**: MySQL 8.0
- **Cache**: Redis 7.0
- **Storage**: AWS S3 / Local
- **Payment**: Stripe API
- **Auth**: JWT

### Admin Dashboard
- **Framework**: Vue 3 + Vite
- **UI**: Element Plus
- **Charts**: ECharts

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- Go 1.21+
- MySQL 8.0
- Redis 7.0

### 1. Setup Database
```bash
mysql -u root -p < database/schema.sql
```

### 2. Backend
```bash
cd backend
cp config.example.yaml config.yaml
# Edit config.yaml with your settings
go mod download
go run main.go
```

### 3. Frontend (User App)
```bash
cd frontend
npm install
npm run dev
# Build APK: npm run build && npx cap sync && npx cap open android
```

### 4. Admin Dashboard
```bash
cd admin
npm install
npm run dev
```

## 📱 Build Android APK

```bash
cd frontend
npm run build
npx cap add android
npx cap sync
npx cap open android
# Build in Android Studio
```

## 🌍 Internationalization

Supported languages:
- 🇺🇸 English (default)
- 🇪🇸 Spanish
- 🇵🇹 Portuguese

Add more in `frontend/src/i18n/locales/`

## 💳 Payment Integration

1. Get Stripe API keys: https://stripe.com
2. Add to `backend/config.yaml`:
```yaml
stripe:
  secret_key: sk_test_xxx
  webhook_secret: whsec_xxx
```

## 🎯 Ad Integration

1. Setup Google AdMob: https://admob.google.com
2. Add App ID in `frontend/capacitor.config.ts`

## 📊 Default Accounts

**Admin Dashboard**
- Email: admin@example.com
- Password: admin123

## 📄 License

MIT License

## 📖 Documentation

- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Get started in 10 minutes
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Production deployment guide
- **[FEATURES.md](FEATURES.md)** - Complete feature list (150+)
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Project overview

## 🎯 Quick Links

- **User App**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Admin Dashboard**: http://localhost:3001
- **Default Admin**: admin@example.com / admin123

## 📊 Project Stats

- **150+ Features** implemented
- **30+ API endpoints**
- **9 database tables**
- **8,000+ lines of code**
- **Multi-language** support (EN/ES/PT)
- **Production-ready**

## 🤝 Contributing

Contributions welcome! Please feel free to submit a Pull Request.

## 📝 Changelog

### v1.0.0 (Initial Release)
- ✅ Complete user mobile app (H5 + Android APK)
- ✅ Full-featured Go backend API
- ✅ Professional admin dashboard
- ✅ Multi-language support (EN/ES/PT)
- ✅ Stripe payment integration
- ✅ Google AdMob support
- ✅ Docker deployment ready
- ✅ Comprehensive documentation

## 🌟 Star This Project

If you find this useful, please give it a star! ⭐

## 📧 Support

For issues and questions:
- Open an issue on GitHub
- Check documentation files
- Email: support@example.com
