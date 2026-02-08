# 🚀 Supabase 部署指南

本指南介绍如何将 Short Drama App 部署到 Supabase。

## 📋 Supabase 服务概览

Supabase 提供以下服务：
- **PostgreSQL 数据库** - 替代 MySQL
- **存储服务** - 存储视频和图片
- **Edge Functions** - 运行 Go 后端 API（Deno/TypeScript）
- **认证服务** - 用户认证（可选，本项目使用自定义 JWT）
- **实时功能** - 实时数据同步（可选）

## 🎯 部署架构

### 方案 1: Supabase + Vercel/Netlify（推荐）

```
前端 (Vercel/Netlify) → 后端 API (Supabase Edge Functions) → Supabase PostgreSQL
```

### 方案 2: Supabase + Railway/Render

```
前端 (Vercel/Netlify) → 后端 API (Railway/Render) → Supabase PostgreSQL
```

### 方案 3: 完全 Supabase（需要重写后端为 Deno）

```
前端 (Supabase Hosting) → Edge Functions (Deno) → Supabase PostgreSQL
```

## 📦 步骤 1: 创建 Supabase 项目

1. 访问 https://supabase.com
2. 注册/登录账户
3. 点击 "New Project"
4. 填写项目信息：
   - **Name**: short-drama-app
   - **Database Password**: 设置强密码（保存好）
   - **Region**: 选择离你最近的区域
5. 等待项目创建完成（约 2 分钟）

## 🗄️ 步骤 2: 设置数据库

### 2.1 运行迁移脚本

1. 在 Supabase Dashboard 中，进入 **SQL Editor**
2. 复制 `supabase/migrations/20240209000000_initial_schema.sql` 的内容
3. 粘贴到 SQL Editor 并执行

或者使用 Supabase CLI：

```bash
# 安装 Supabase CLI
npm install -g supabase

# 登录
supabase login

# 链接项目
supabase link --project-ref your-project-ref

# 运行迁移
supabase db push
```

### 2.2 获取数据库连接信息

在 Supabase Dashboard → **Settings** → **Database**：
- **Host**: `db.xxxxx.supabase.co`
- **Port**: `5432`
- **Database**: `postgres`
- **User**: `postgres`
- **Password**: 你设置的密码
- **Connection String**: `postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres`

## 🔧 步骤 3: 配置后端连接 Supabase

### 3.1 修改后端配置

创建 `backend/config.supabase.yaml`:

```yaml
server:
  port: 9090
  mode: release

database:
  host: db.xxxxx.supabase.co  # 你的 Supabase 数据库主机
  port: 5432
  user: postgres
  password: your_supabase_password
  dbname: postgres
  max_idle_conns: 10
  max_open_conns: 100

redis:
  host: localhost  # Supabase 不提供 Redis，可以使用 Upstash Redis
  port: 6379
  password: ""
  db: 0

jwt:
  secret: your_jwt_secret_key_change_this_in_production
  expires_hours: 720

stripe:
  secret_key: sk_live_xxxxx
  webhook_secret: whsec_xxxxx
  price_monthly: price_xxxxx
  price_yearly: price_xxxxx

aws:
  region: us-east-1
  access_key_id: your_access_key
  secret_access_key: your_secret_key
  s3_bucket: your-bucket-name
  cloudfront_domain: ""

cors:
  allowed_origins:
    - https://your-frontend-domain.com
  allow_credentials: true
```

### 3.2 修改 Go 数据库驱动

Supabase 使用 PostgreSQL，需要修改 Go 代码使用 PostgreSQL 驱动：

1. 更新 `backend/go.mod`，添加 PostgreSQL 驱动：
```bash
cd backend
go get github.com/lib/pq
go get gorm.io/driver/postgres
```

2. 修改 `backend/database/database.go`：

```go
import (
    "gorm.io/driver/postgres"
    // 移除 mysql 驱动
    // "gorm.io/driver/mysql"
)
```

3. 更新数据库连接字符串格式：

```go
// MySQL 格式: "user:password@tcp(host:port)/dbname?charset=utf8mb4&parseTime=True&loc=Local"
// PostgreSQL 格式: "host=host user=user password=password dbname=dbname port=port sslmode=disable TimeZone=Asia/Shanghai"
dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%d sslmode=require TimeZone=UTC",
    cfg.Database.Host,
    cfg.Database.User,
    cfg.Database.Password,
    cfg.Database.DBName,
    cfg.Database.Port,
)

db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
```

## 📦 步骤 4: 配置存储（视频和图片）

### 4.1 创建存储桶

在 Supabase Dashboard → **Storage**：

1. 创建存储桶：
   - **Name**: `videos` (公开)
   - **Name**: `thumbnails` (公开)
   - **Name**: `posters` (公开)

2. 设置存储策略（可选，如果需要私有存储）

### 4.2 更新视频 URL

将视频和图片上传到 Supabase Storage，URL 格式：
```
https://[project-ref].supabase.co/storage/v1/object/public/videos/[filename]
```

## 🚀 步骤 5: 部署后端

### 选项 A: Railway（推荐）

1. 访问 https://railway.app
2. 连接 GitHub 仓库
3. 选择项目，Railway 会自动检测 Go 项目
4. 设置环境变量：
   - `CONFIG_PATH`: `/app/config.yaml`
   - 或直接设置数据库连接字符串等
5. 部署

### 选项 B: Render

1. 访问 https://render.com
2. 创建新的 **Web Service**
3. 连接 GitHub 仓库
4. 设置：
   - **Build Command**: `cd backend && go build -o short-drama-api main.go`
   - **Start Command**: `./backend/short-drama-api`
5. 设置环境变量
6. 部署

### 选项 C: Fly.io

```bash
# 安装 flyctl
curl -L https://fly.io/install.sh | sh

# 登录
fly auth login

# 初始化
cd backend
fly launch

# 部署
fly deploy
```

## 🌐 步骤 6: 部署前端

### 选项 A: Vercel（推荐）

1. 访问 https://vercel.com
2. 导入 GitHub 仓库
3. 设置：
   - **Framework Preset**: Vite
   - **Root Directory**: `frontend`
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`
4. 环境变量：
   - `VITE_API_BASE_URL`: `https://your-backend-api.com/api`
5. 部署

### 选项 B: Netlify

1. 访问 https://netlify.com
2. 导入 GitHub 仓库
3. 设置：
   - **Base directory**: `frontend`
   - **Build command**: `npm run build`
   - **Publish directory**: `frontend/dist`
4. 环境变量：
   - `VITE_API_BASE_URL`: `https://your-backend-api.com/api`
5. 部署

### 选项 C: Supabase Hosting（静态文件）

```bash
# 构建前端
cd frontend
npm run build

# 使用 Supabase CLI 部署
supabase storage upload dist public
```

## 🔄 步骤 7: 配置 Redis（可选）

Supabase 不提供 Redis，可以使用：

### Upstash Redis（推荐）

1. 访问 https://upstash.com
2. 创建 Redis 数据库
3. 获取连接信息
4. 更新后端配置中的 Redis 设置

### Railway Redis

在 Railway 中添加 Redis 服务，获取连接字符串。

## 📝 环境变量配置

### 后端环境变量（Railway/Render）

```bash
CONFIG_PATH=/app/config.yaml
# 或直接设置：
DATABASE_HOST=db.xxxxx.supabase.co
DATABASE_PORT=5432
DATABASE_USER=postgres
DATABASE_PASSWORD=your_password
DATABASE_NAME=postgres
JWT_SECRET=your_jwt_secret
```

### 前端环境变量（Vercel/Netlify）

```bash
VITE_API_BASE_URL=https://your-backend-api.com/api
```

## 🔐 安全配置

### 1. 数据库连接使用 SSL

在 Supabase 配置中，确保使用 SSL 连接：
```yaml
database:
  sslmode: require  # 或 verify-full
```

### 2. Row Level Security (RLS)

Supabase 默认启用 RLS，如果需要，可以配置策略：

```sql
-- 示例：允许所有用户读取 dramas
ALTER TABLE dramas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access" ON dramas
    FOR SELECT USING (true);
```

### 3. API 密钥

在 Supabase Dashboard → **Settings** → **API**：
- **anon key**: 用于客户端
- **service_role key**: 用于服务器端（保密！）

## 🧪 测试部署

1. **测试数据库连接**：
```bash
psql "postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres"
```

2. **测试 API**：
```bash
curl https://your-backend-api.com/api/health
```

3. **测试前端**：
访问部署的前端 URL

## 📚 相关资源

- [Supabase 文档](https://supabase.com/docs)
- [PostgreSQL 迁移指南](https://supabase.com/docs/guides/database/migrations)
- [Supabase Storage](https://supabase.com/docs/guides/storage)
- [Railway 部署指南](https://docs.railway.app)
- [Vercel 部署指南](https://vercel.com/docs)

## 🆘 常见问题

### Q: 如何迁移现有 MySQL 数据到 Supabase？

A: 使用数据迁移工具：
```bash
# 导出 MySQL 数据
mysqldump -u user -p database > data.sql

# 转换为 PostgreSQL 格式（需要手动调整）
# 或使用工具如 pgloader
```

### Q: Supabase 有 Redis 吗？

A: 没有，需要使用第三方服务如 Upstash 或 Railway Redis。

### Q: 如何备份 Supabase 数据库？

A: Supabase 自动备份，也可以在 Dashboard 中手动备份。

### Q: Edge Functions 支持 Go 吗？

A: 目前只支持 Deno/TypeScript，Go 后端需要部署到 Railway/Render/Fly.io。
