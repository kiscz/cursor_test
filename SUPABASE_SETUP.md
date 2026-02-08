# 🎯 Supabase 部署检查清单

## ✅ 部署前准备

### 1. Supabase 项目设置
- [ ] 创建 Supabase 项目
- [ ] 保存数据库密码
- [ ] 获取数据库连接信息

### 2. 数据库迁移
- [ ] 在 Supabase SQL Editor 运行迁移脚本
- [ ] 验证表已创建（检查 `users`, `dramas`, `episodes` 等表）

### 3. 后端配置
- [ ] 更新 `backend/config.supabase.yaml` 中的数据库连接信息
- [ ] 设置 JWT secret
- [ ] 配置 Stripe keys（如果需要）
- [ ] 设置 Redis（Upstash 或其他服务）

### 4. 前端配置
- [ ] 设置 `VITE_API_BASE_URL` 环境变量
- [ ] 更新 CORS 配置（后端）

### 5. 存储配置（可选）
- [ ] 在 Supabase Storage 创建存储桶
- [ ] 上传测试视频/图片
- [ ] 更新数据库中的 URL

## 🚀 快速部署命令

### Railway（后端）

```bash
# 1. 安装 Railway CLI
npm i -g @railway/cli

# 2. 登录
railway login

# 3. 初始化项目
railway init

# 4. 链接到项目
railway link

# 5. 设置环境变量
railway variables set USE_POSTGRES=true
railway variables set CONFIG_PATH=/app/config.supabase.yaml
# 或直接设置数据库连接信息

# 6. 部署
railway up
```

### Vercel（前端）

```bash
# 1. 安装 Vercel CLI
npm i -g vercel

# 2. 登录
vercel login

# 3. 部署
cd frontend
vercel --prod

# 4. 设置环境变量
vercel env add VITE_API_BASE_URL production
```

## 📝 环境变量参考

### Railway（后端）

```bash
USE_POSTGRES=true
DATABASE_HOST=db.xxxxx.supabase.co
DATABASE_PORT=5432
DATABASE_USER=postgres
DATABASE_PASSWORD=your_password
DATABASE_NAME=postgres
JWT_SECRET=your_random_secret_here
REDIS_HOST=your-redis-host.upstash.io
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password
```

### Vercel（前端）

```bash
VITE_API_BASE_URL=https://your-backend.up.railway.app/api
```

## 🔍 验证部署

1. **检查数据库连接**:
   ```bash
   psql "postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres"
   ```

2. **测试 API**:
   ```bash
   curl https://your-backend.up.railway.app/api/health
   ```

3. **测试前端**:
   访问 Vercel 部署的 URL

## 🆘 故障排除

### 数据库连接失败
- 检查密码是否正确
- 确保使用 SSL (`sslmode=require`)
- 检查 Supabase 项目是否激活

### 后端启动失败
- 查看 Railway 日志
- 检查环境变量是否正确
- 确认 PostgreSQL 驱动已安装

### 前端无法连接后端
- 检查 `VITE_API_BASE_URL` 是否正确
- 检查后端 CORS 配置
- 查看浏览器控制台错误
