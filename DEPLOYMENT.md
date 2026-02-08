# Deployment Guide

## Prerequisites

- **Node.js** 18+ and npm
- **Go** 1.21+
- **MySQL** 8.0+
- **Redis** 7.0+
- **AWS Account** (for S3 storage) or local storage
- **Stripe Account** (for payments)

---

## 1. Database Setup

### Create Database

```bash
mysql -u root -p
```

```sql
CREATE DATABASE short_drama CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EXIT;
```

### Import Schema

```bash
mysql -u root -p short_drama < database/schema.sql
```

---

## 2. Backend Setup

### Install Dependencies

```bash
cd backend
go mod download
```

### Configuration

```bash
cp config.example.yaml config.yaml
```

Edit `config.yaml` with your settings:

- Database credentials
- Redis connection
- JWT secret (change in production!)
- Stripe API keys
- AWS S3 credentials

### Run Backend

```bash
go run main.go
```

Backend will start on `http://localhost:8080`

### Build for Production

```bash
go build -o short-drama-api main.go
./short-drama-api
```

---

## 3. Frontend (User App) Setup

### Install Dependencies

```bash
cd frontend
npm install
```

### Configuration

```bash
cp .env.example .env
```

Edit `.env`:
```
VITE_API_BASE_URL=http://localhost:8080/api
```

### Development

```bash
npm run dev
```

Frontend will start on `http://localhost:3000`

### Production Build

```bash
npm run build
```

Built files will be in `dist/` folder.

---

## 4. Build Android APK

### Prerequisites

- Android Studio
- Java JDK 11+

### Steps

```bash
cd frontend

# Build web app
npm run build

# Add Android platform
npx cap add android

# Sync files
npx cap sync

# Open in Android Studio
npx cap open android
```

In Android Studio:
1. Update `app/build.gradle` with your app details
2. Build → Generate Signed Bundle / APK
3. Select APK
4. Create keystore or use existing
5. Build APK

---

## 5. Admin Dashboard Setup

### Install Dependencies

```bash
cd admin
npm install
```

### Configuration

```bash
cp .env.example .env
```

### Development

```bash
npm run dev
```

Admin dashboard will start on `http://localhost:3001`

### Production Build

```bash
npm run build
```

---

## 6. Production Deployment

### Option 1: Docker (Recommended)

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: your_password
      MYSQL_DATABASE: short_drama
    volumes:
      - mysql_data:/var/lib/mysql
      - ./database/schema.sql:/docker-entrypoint-initdb.d/schema.sql
    ports:
      - "3306:3306"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  backend:
    build: ./backend
    ports:
      - "8080:8080"
    depends_on:
      - mysql
      - redis
    environment:
      - CONFIG_PATH=/app/config.yaml

  frontend:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - backend

  admin:
    build: ./admin
    ports:
      - "3001:80"
    depends_on:
      - backend

volumes:
  mysql_data:
```

Run:
```bash
docker-compose up -d
```

### Option 2: Cloud Deployment

#### Backend (Go)
- **AWS EC2** / **DigitalOcean** / **Google Cloud**
- Use systemd service
- Nginx reverse proxy
- SSL with Let's Encrypt

#### Frontend & Admin
- **Vercel** / **Netlify** (static hosting)
- **AWS S3 + CloudFront**
- **Firebase Hosting**

#### Database
- **AWS RDS** (MySQL)
- **Amazon ElastiCache** (Redis)

#### Storage
- **AWS S3** for videos
- **CloudFront** for CDN

---

## 7. Environment Variables (Production)

### Backend

```yaml
server:
  mode: release

jwt:
  secret: STRONG_RANDOM_SECRET_CHANGE_THIS

stripe:
  secret_key: sk_live_xxxxx
  webhook_secret: whsec_xxxxx

aws:
  access_key_id: YOUR_ACCESS_KEY
  secret_access_key: YOUR_SECRET_KEY
```

### Frontend

```env
VITE_API_BASE_URL=https://api.yourdomain.com/api
```

---

## 8. SSL/HTTPS Setup

### Using Nginx

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Get SSL Certificate

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d api.yourdomain.com
```

---

## 9. Monitoring & Logs

### Backend Logs

```bash
# Systemd service
journalctl -u short-drama-api -f

# Or use log files
tail -f /var/log/short-drama/api.log
```

### Application Monitoring

- **Prometheus** + **Grafana**
- **New Relic**
- **DataDog**

---

## 10. Backup Strategy

### Database Backup

```bash
# Daily backup
mysqldump -u root -p short_drama > backup_$(date +%Y%m%d).sql

# Automated with cron
0 2 * * * /usr/bin/mysqldump -u root -p'password' short_drama > /backups/backup_$(date +\%Y\%m\%d).sql
```

### Media Backup

AWS S3 versioning and cross-region replication

---

## Troubleshooting

### Backend won't start
- Check MySQL connection
- Verify Redis is running
- Check config.yaml syntax

### Frontend can't connect to backend
- Check CORS settings in backend
- Verify API URL in .env
- Check network/firewall

### APK build issues
- Update Android SDK
- Check Capacitor version compatibility
- Clear cache: `npx cap sync android`

---

## Support

For issues, check:
- Backend logs
- Browser console (Frontend)
- MySQL error logs
- Redis logs

Contact: support@yourdomain.com
