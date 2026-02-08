# 🚀 Supabase 快速部署指南

## 📋 前置要求

1. Supabase 账户（免费）：https://supabase.com
2. GitHub 账户（用于部署）
3. Vercel/Netlify 账户（免费，用于前端）

## ⚡ 5 分钟快速部署

### 步骤 1: 创建 Supabase 项目（2 分钟）

1. 访问 https://supabase.com，注册/登录
2. 点击 **"New Project"**
3. 填写信息：
   - **Name**: `short-drama-app`
   - **Database Password**: 设置强密码（**保存好！**）
   - **Region**: 选择最近的区域
4. 等待创建完成（约 2 分钟）

### 步骤 2: 运行数据库迁移（1 分钟）

1. 在 Supabase Dashboard，点击左侧 **SQL Editor**
2. 点击 **"New query"**
3. 复制 `supabase/migrations/20240209000000_initial_schema.sql` 的全部内容
4. 粘贴到 SQL Editor
5. 点击 **"Run"** 执行

✅ 数据库表已创建！

### 步骤 3: 获取连接信息（30 秒）

在 Supabase Dashboard → **Settings** → **Database**：

- **Connection string**: `postgresql://postgres:[YOUR-PASSWORD]@db.xxxxx.supabase.co:5432/postgres`
- **Host**: `db.xxxxx.supabase.co`
- **Port**: `5432`
- **Database**: `postgres`
- **User**: `postgres`
- **Password**: 你设置的密码

### 步骤 4: 部署后端到 Railway（推荐）

1. 访问 https://railway.app，使用 GitHub 登录
2. 点击 **"New Project"** → **"Deploy from GitHub repo"**
3. 选择 `kiscz/cursor_test` 仓库
4. 点击 **"Add Service"** → **"GitHub Repo"**
5. 设置：
   - **Root Directory**: `backend`
   - **Build Command**: `go build -o short-drama-api main.go`
   - **Start Command**: `./short-drama-api`
6. 添加环境变量：
   ```
   CONFIG_PATH=/app/config.supabase.yaml
   ```
   或直接设置：
   ```
   DATABASE_HOST=db.xxxxx.supabase.co
   DATABASE_PORT=5432
   DATABASE_USER=postgres
   DATABASE_PASSWORD=your_password
   DATABASE_NAME=postgres
   JWT_SECRET=your_random_secret
   ```
7. Railway 会自动部署

✅ 后端 API 已部署！

### 步骤 5: 部署前端到 Vercel（1 分钟）

1. 访问 https://vercel.com，使用 GitHub 登录
2. 点击 **"Add New"** → **"Project"**
3. 导入 `kiscz/cursor_test` 仓库
4. 配置：
   - **Framework Preset**: Vite
   - **Root Directory**: `frontend`
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`
5. 环境变量：
   ```
   VITE_API_BASE_URL=https://your-railway-app.up.railway.app/api
   ```
   （替换为 Railway 给你的后端 URL）
6. 点击 **"Deploy"**

✅ 前端已部署！

### 步骤 6: 配置 Redis（可选，1 分钟）

Supabase 不提供 Redis，使用 Upstash（免费）：

1. 访问 https://upstash.com，注册账户
2. 创建 Redis 数据库
3. 复制连接信息
4. 在 Railway 后端环境变量中添加：
   ```
   REDIS_HOST=your-redis-host.upstash.io
   REDIS_PORT=6379
   REDIS_PASSWORD=your-redis-password
   ```
5. 重启后端服务

## 🎯 访问应用

- **前端**: https://your-app.vercel.app
- **后端 API**: https://your-app.up.railway.app/api
- **管理后台**: 需要单独部署（类似前端部署）

## 📝 修改后端支持 PostgreSQL

由于当前后端使用 MySQL，需要修改以支持 PostgreSQL：

### 选项 A: 修改代码（推荐）

1. 更新 `backend/go.mod`：
```bash
cd backend
go get gorm.io/driver/postgres
```

2. 修改 `backend/database/database.go`，将 MySQL 驱动改为 PostgreSQL：
```go
import "gorm.io/driver/postgres"

// 修改 DSN 格式
dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%d sslmode=require TimeZone=UTC",
    cfg.Database.Host,
    cfg.Database.User,
    cfg.Database.Password,
    cfg.Database.DBName,
    cfg.Database.Port,
)

db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
```

3. 移除 MySQL 特定的代码（如 `SET FOREIGN_KEY_CHECKS`）

### 选项 B: 使用构建标签（已创建 `database_postgres.go`）

编译时使用：
```bash
go build -tags postgres -o short-drama-api main.go
```

## 🔧 配置 Supabase Storage（存储视频）

1. 在 Supabase Dashboard → **Storage**
2. 创建存储桶：
   - `videos` (公开)
   - `thumbnails` (公开)
   - `posters` (公开)
3. 上传文件后，URL 格式：
   ```
   https://[project-ref].supabase.co/storage/v1/object/public/videos/[filename]
   ```

## 📚 详细文档

查看 [SUPABASE_DEPLOY.md](./SUPABASE_DEPLOY.md) 获取完整部署指南。

## 🆘 常见问题

**Q: Railway 部署失败？**
- 检查环境变量是否正确
- 查看 Railway 日志

**Q: 数据库连接失败？**
- 检查 Supabase 数据库密码
- 确保使用 SSL 连接（`sslmode=require`）

**Q: 前端无法连接后端？**
- 检查 `VITE_API_BASE_URL` 是否正确
- 检查后端 CORS 配置
