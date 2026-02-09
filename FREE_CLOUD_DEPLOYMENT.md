# 免费后台部署云资源指南

本文档列出了适合部署 Short Drama App 后端的免费云服务选项。

## 🚀 推荐方案（按优先级）

### 1. Railway ⭐⭐⭐⭐⭐
**最适合：Go 后端 + PostgreSQL + Redis**

- **免费额度**：
  - $5/月免费额度（永久）
  - 500 小时运行时间/月
  - 512MB RAM
  - 1GB 磁盘空间
  
- **优点**：
  - 支持 Docker 部署
  - 自动 HTTPS
  - 环境变量管理
  - PostgreSQL、MySQL、Redis 等数据库一键添加
  - 简单易用，GitHub 集成
  
- **限制**：
  - 免费额度有限，超出需付费
  - 休眠机制（不活跃时暂停）
  
- **部署步骤**：
  1. 注册 https://railway.app
  2. 连接 GitHub 仓库
  3. 选择项目，Railway 自动检测 Dockerfile
  4. 添加 PostgreSQL 和 Redis 服务
  5. 配置环境变量
  6. 部署完成

---

### 2. Render ⭐⭐⭐⭐
**最适合：Go 后端 + PostgreSQL**

- **免费额度**：
  - Web 服务：750 小时/月（约 31 天）
  - PostgreSQL：90 天免费试用
  - Redis：90 天免费试用
  
- **优点**：
  - 支持 Docker 和原生构建
  - 自动 HTTPS
  - GitHub 自动部署
  - 免费 PostgreSQL 数据库（90 天）
  
- **限制**：
  - 不活跃时自动休眠（15 分钟无请求）
  - 免费数据库仅 90 天
  
- **部署步骤**：
  1. 注册 https://render.com
  2. 创建 Web Service，连接 GitHub
  3. 选择 Docker 或 Go 构建
  4. 添加 PostgreSQL 数据库
  5. 配置环境变量
  6. 部署

---

### 3. Fly.io ⭐⭐⭐⭐
**最适合：Go 后端 + PostgreSQL**

- **免费额度**：
  - 3 个共享 CPU 实例
  - 3GB 持久化存储
  - 160GB 出站流量/月
  
- **优点**：
  - 全球边缘部署
  - 支持 Docker
  - PostgreSQL 数据库（免费层）
  - Redis 支持
  
- **限制**：
  - 需要信用卡验证（但不会扣费）
  - 配置相对复杂
  
- **部署步骤**：
  1. 注册 https://fly.io
  2. 安装 flyctl CLI
  3. 运行 `fly launch`
  4. 添加 PostgreSQL：`fly postgres create`
  5. 配置 secrets
  6. 部署

---

### 4. Supabase ⭐⭐⭐⭐⭐
**最适合：PostgreSQL 数据库 + 存储 + Edge Functions**

- **免费额度**：
  - PostgreSQL：500MB 数据库
  - 存储：1GB
  - Edge Functions：500K 调用/月
  - API 请求：50K/月
  
- **优点**：
  - 完整的 PostgreSQL 数据库
  - 实时订阅
  - 存储服务
  - Edge Functions（Deno）
  - 自动 API 生成
  
- **限制**：
  - 数据库大小限制 500MB
  - API 请求有限制
  
- **部署步骤**：
  1. 注册 https://supabase.com
  2. 创建项目
  3. 运行数据库迁移（见 `SUPABASE_DEPLOY.md`）
  4. 后端部署到 Railway/Render（使用 Supabase PostgreSQL）
  5. 配置连接字符串

---

### 5. Vercel ⭐⭐⭐
**最适合：Serverless Functions（Node.js/Python/Go）**

- **免费额度**：
  - Serverless Functions：100GB 小时/月
  - 100GB 带宽/月
  
- **优点**：
  - 全球 CDN
  - 自动 HTTPS
  - GitHub 集成
  - 支持 Go Serverless Functions
  
- **限制**：
  - 不适合长时间运行的 Go 服务
  - 更适合 API 端点
  
- **部署步骤**：
  1. 注册 https://vercel.com
  2. 导入 GitHub 项目
  3. 配置 `vercel.json`
  4. 部署（自动）

---

## 🗄️ 免费数据库服务

### PostgreSQL
- **Supabase**：500MB 免费（推荐）
- **Neon**：512MB 免费，自动暂停
- **ElephantSQL**：20MB 免费（很小）
- **Railway**：$5 免费额度内使用

### MySQL
- **PlanetScale**：5GB 免费，无服务器 MySQL
- **Railway**：$5 免费额度内使用
- **Render**：90 天免费试用

### Redis
- **Upstash**：10K 命令/天免费
- **Redis Cloud**：30MB 免费
- **Railway**：$5 免费额度内使用

---

## 💰 云服务商免费层

### AWS Free Tier
- **EC2**：t2.micro 实例 750 小时/月（12 个月）
- **RDS**：MySQL/PostgreSQL 20GB（12 个月）
- **ElastiCache**：Redis 750 小时/月（12 个月）
- **S3**：5GB 存储（永久）

### Google Cloud Platform (GCP)
- **Compute Engine**：$300 免费额度（90 天）
- **Cloud SQL**：包含在 $300 额度内
- **Cloud Storage**：5GB（永久）

### Microsoft Azure
- **Virtual Machines**：$200 免费额度（30 天）
- **Azure Database**：包含在 $200 额度内
- **Blob Storage**：5GB（永久）

---

## 🎯 推荐组合方案

### 方案 1：Railway（最简单）⭐⭐⭐⭐⭐
```
后端：Railway（Go）
数据库：Railway PostgreSQL
缓存：Railway Redis
存储：Railway Volume 或 Supabase Storage
```
**优点**：一站式解决方案，配置简单
**成本**：完全免费（在 $5/月额度内）

### 方案 2：Render + Supabase ⭐⭐⭐⭐
```
后端：Render（Go）
数据库：Supabase PostgreSQL
缓存：Upstash Redis（免费）
存储：Supabase Storage
```
**优点**：数据库稳定，后端免费
**成本**：完全免费（Render 休眠，Supabase 免费层）

### 方案 3：Fly.io + Supabase ⭐⭐⭐⭐
```
后端：Fly.io（Go）
数据库：Supabase PostgreSQL
缓存：Upstash Redis
存储：Supabase Storage
```
**优点**：全球边缘部署，性能好
**成本**：完全免费（在免费额度内）

### 方案 4：Vercel + Supabase（Serverless）⭐⭐⭐
```
API：Vercel Serverless Functions（Go）
数据库：Supabase PostgreSQL
缓存：Upstash Redis
存储：Supabase Storage
```
**优点**：全球 CDN，自动扩展
**限制**：需要将 Go 后端改为 Serverless Functions

---

## 📝 快速开始指南

### Railway 部署（推荐）

1. **注册 Railway**
   ```bash
   # 访问 https://railway.app
   # 使用 GitHub 账号登录
   ```

2. **创建项目**
   - 点击 "New Project"
   - 选择 "Deploy from GitHub repo"
   - 选择你的仓库

3. **配置服务**
   - Railway 会自动检测根目录的 `Dockerfile` 和 `railway.json`
   - 如果使用 Dockerfile，确保根目录有 `Dockerfile` 文件

4. **添加数据库**
   - 点击 "+ New"
   - 选择 "Database" → "Add PostgreSQL"
   - 选择 "Add Redis"

5. **配置环境变量**
   - 在服务设置中添加环境变量：
     - `DATABASE_URL`: PostgreSQL 连接字符串（Railway 自动提供）
     - `REDIS_URL`: Redis 连接字符串（Railway 自动提供）
     - `JWT_SECRET`: JWT 密钥（自定义）
     - `CONFIG_PATH`: `/root/config.yaml`（可选）
   
   或者通过 Railway 的变量引用：
   - `DATABASE_HOST`: `${{Postgres.PGHOST}}`
   - `DATABASE_PORT`: `${{Postgres.PGPORT}}`
   - `DATABASE_USER`: `${{Postgres.PGUSER}}`
   - `DATABASE_PASSWORD`: `${{Postgres.PGPASSWORD}}`
   - `DATABASE_NAME`: `${{Postgres.PGDATABASE}}`

6. **部署**
   - Railway 自动构建并部署
   - 查看日志确认部署成功

### Render 部署

1. **注册 Render**
   ```bash
   # 访问 https://render.com
   # 使用 GitHub 账号登录
   ```

2. **创建 Web Service**
   - 点击 "New +" → "Web Service"
   - 连接 GitHub 仓库
   - 选择构建方式（Docker 或 Go）

3. **添加 PostgreSQL**
   - 点击 "New +" → "PostgreSQL"
   - 选择免费计划（90 天）

4. **配置环境变量**
   - 在服务设置中添加环境变量
   - 使用 Render 提供的数据库 URL

5. **部署**
   - Render 自动构建和部署

---

## ⚠️ 注意事项

1. **免费额度限制**
   - 大多数服务有使用限制
   - 超出限制可能暂停服务或要求升级

2. **休眠机制**
   - Render、Railway 等会在不活跃时休眠
   - 首次请求可能较慢（冷启动）

3. **数据持久化**
   - 确保重要数据有备份
   - 免费层可能不保证数据持久化

4. **环境变量安全**
   - 不要在代码中硬编码密钥
   - 使用各平台的环境变量管理

5. **监控和日志**
   - 免费层通常提供基本监控
   - 日志查看可能有限制

---

## 🔗 相关文档

- [Supabase 部署指南](./SUPABASE_DEPLOY.md)
- [Supabase 快速开始](./SUPABASE_QUICK_START.md)
- [GitHub 部署指南](./GITHUB_DEPLOY.md)

---

## 📊 对比表

| 服务 | 免费额度 | 数据库 | Redis | 休眠 | 推荐度 |
|------|---------|--------|-------|------|--------|
| Railway | $5/月 | ✅ | ✅ | 是 | ⭐⭐⭐⭐⭐ |
| Render | 750h/月 | ✅(90天) | ✅(90天) | 是 | ⭐⭐⭐⭐ |
| Fly.io | 3实例 | ✅ | ✅ | 否 | ⭐⭐⭐⭐ |
| Supabase | 500MB | ✅ | ❌ | 否 | ⭐⭐⭐⭐⭐ |
| Vercel | 100GBh | ❌ | ❌ | 否 | ⭐⭐⭐ |

---

**推荐**：对于 Short Drama App，建议使用 **Railway** 或 **Render + Supabase** 组合，配置简单，免费额度充足。
