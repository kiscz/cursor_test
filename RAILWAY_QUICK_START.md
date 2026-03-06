# Railway 快速部署指南（5 分钟版）

## ⚡ 超快速部署步骤

### 1. 连接 GitHub（1 分钟）

1. 访问 https://railway.app
2. 登录（使用 GitHub）
3. **"New Project"** → **"Deploy from GitHub repo"**
4. 选择你的仓库

### 2. 添加数据库（1 分钟）

1. 点击 **"+ New"** → **"Database"** → **"Add PostgreSQL"**
2. 等待创建完成

### 3. 配置环境变量（2 分钟）

点击后端服务 → **"Variables"** → 添加以下变量：

**方式 A：使用 DATABASE_URL（推荐，最简单）**
```bash
# 数据库连接（Railway 自动提供）
DATABASE_URL=${{Postgres.DATABASE_PRIVATE_URL}}

# 使用 PostgreSQL
USE_POSTGRES=true
```

**方式 B：使用分项变量**
```bash
# 数据库（使用 Railway 变量引用）
DATABASE_HOST=${{Postgres.PGHOST}}
DATABASE_PORT=${{Postgres.PGPORT}}
DATABASE_USER=${{Postgres.PGUSER}}
DATABASE_PASSWORD=${{Postgres.PGPASSWORD}}
DATABASE_NAME=${{Postgres.PGDATABASE}}

# 使用 PostgreSQL
USE_POSTGRES=true

# 服务器
SERVER_PORT=9090
SERVER_MODE=release

# JWT（重要：修改为强密钥）
JWT_SECRET=your_production_jwt_secret_key_change_this
JWT_EXPIRES_HOURS=720

# CORS（根据你的前端域名）
CORS_ALLOWED_ORIGINS=https://your-frontend.com
CORS_ALLOW_CREDENTIALS=true

# Redis（可选，不添加 Redis 时设为 false）
USE_REDIS=false
```

### 4. 运行数据库迁移（1 分钟）

**方法 A：使用 Railway Web Console**
1. 点击 PostgreSQL 服务
2. 点击 **"Query"** 标签页
3. 复制 `supabase/migrations/20240209000000_initial_schema.sql` 内容
4. 粘贴并点击 **"Run"**

**方法 B：使用 Railway CLI**
```bash
railway login
railway link
railway connect postgres
# 然后在 psql 中执行 SQL
```

### 5. 完成！

Railway 会自动部署，查看 **"Logs"** 确认服务运行正常。

---

## 🔧 环境变量完整列表

### PostgreSQL 配置（Railway 默认）

```bash
# 数据库配置（使用 Railway 变量引用）
DATABASE_HOST=${{Postgres.PGHOST}}
DATABASE_PORT=${{Postgres.PGPORT}}
DATABASE_USER=${{Postgres.PGUSER}}
DATABASE_PASSWORD=${{Postgres.PGPASSWORD}}
DATABASE_NAME=${{Postgres.PGDATABASE}}
USE_POSTGRES=true

# 服务器配置
SERVER_PORT=9090
SERVER_MODE=release

# JWT 配置
JWT_SECRET=your_production_jwt_secret_key_change_this
JWT_EXPIRES_HOURS=720
```

### MySQL 配置（使用外部 MySQL 服务）

```bash
# 数据库配置（外部 MySQL）
DATABASE_HOST=your-mysql-host.com
DATABASE_PORT=3306
DATABASE_USER=your_mysql_user
DATABASE_PASSWORD=your_mysql_password
DATABASE_NAME=short_drama
USE_POSTGRES=false

# 服务器配置
SERVER_PORT=9090
SERVER_MODE=release

# JWT 配置
JWT_SECRET=your_production_jwt_secret_key_change_this
JWT_EXPIRES_HOURS=720
```

⚠️ **注意**：Railway 默认只提供 PostgreSQL。如需使用 MySQL，请参考 [RAILWAY_MYSQL_CONFIG.md](./RAILWAY_MYSQL_CONFIG.md)

### 可选变量

```bash
# Redis（如果添加了 Redis 服务，详见 RAILWAY_REDIS_CONFIG.md）
REDIS_URL=${{Redis.REDIS_URL}}
# 或分项配置：
# REDIS_HOST=${{Redis.REDIS_HOST}}
# REDIS_PORT=${{Redis.REDIS_PORT}}
# REDIS_PASSWORD=${{Redis.REDIS_PASSWORD}}

# CORS
CORS_ALLOWED_ORIGINS=https://your-frontend.com,https://your-admin.com
CORS_ALLOW_CREDENTIALS=true

# Stripe（如果使用支付）
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PRICE_MONTHLY=price_...
STRIPE_PRICE_YEARLY=price_...

# AWS S3（如果使用存储）
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_S3_BUCKET=...
```

---

## 📝 重要提示

1. **JWT_SECRET**：生产环境必须使用强密钥（至少 32 字符）
2. **USE_POSTGRES**：必须设置为 `true`（Railway 使用 PostgreSQL）
3. **端口**：确保设置为 `9090`（与代码一致）
4. **CORS**：根据你的前端域名配置

---

## 🐛 常见问题

**Q: 服务启动失败？**
- 检查环境变量是否完整
- 查看 Logs 标签页的错误信息

**Q: 数据库连接失败？**
- 确认 `USE_POSTGRES=true`
- 检查数据库变量引用格式：`${{Postgres.PGHOST}}`

**Q: 如何查看 API？**
- Railway 会自动生成公共域名
- 格式：`your-service.up.railway.app`
- 测试：`https://your-service.up.railway.app/api/health`

---

详细部署指南请查看：
- [RAILWAY_DEPLOY.md](./RAILWAY_DEPLOY.md)
- [RAILWAY_REDIS_CONFIG.md](./RAILWAY_REDIS_CONFIG.md) - Redis 配置
