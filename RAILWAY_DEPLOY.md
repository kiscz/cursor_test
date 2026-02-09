# Railway 部署完整指南

本指南将带你完成 Short Drama App 在 Railway 上的完整部署过程。

## 📋 前置要求

1. **GitHub 账户**：用于连接代码仓库
2. **Railway 账户**：访问 https://railway.app 注册（可使用 GitHub 账号登录）
3. **代码已推送到 GitHub**：确保代码在 GitHub 仓库中

---

## 🚀 部署步骤

### 步骤 1: 注册并登录 Railway（2 分钟）

1. 访问 https://railway.app
2. 点击右上角 **"Login"** 或 **"Start a New Project"**
3. 选择 **"Login with GitHub"**
4. 授权 Railway 访问你的 GitHub 账户

✅ **完成标志**：看到 Railway Dashboard

---

### 步骤 2: 创建新项目（1 分钟）

1. 在 Railway Dashboard，点击 **"New Project"**
2. 选择 **"Deploy from GitHub repo"**
3. 如果首次使用，点击 **"Configure GitHub App"** 授权
4. 在仓库列表中找到你的仓库（如 `kiscz/cursor_test`）
5. 点击仓库名称

✅ **完成标志**：Railway 开始检测项目配置

---

### 步骤 3: 配置后端服务（3 分钟）

Railway 会自动检测到 `Dockerfile` 和 `railway.json`，开始构建。

#### 3.1 等待首次构建完成

- Railway 会自动：
  - 检测 Dockerfile
  - 开始构建 Docker 镜像
  - 部署服务

⏱️ **预计时间**：3-5 分钟

#### 3.2 查看构建日志

- 点击服务名称（如 `cursor_test`）
- 查看 **"Deployments"** 标签页
- 点击最新的部署查看日志

✅ **成功标志**：看到 "Build successful" 或 "Deployment successful"

---

### 步骤 4: 添加 PostgreSQL 数据库（2 分钟）

1. 在项目页面，点击 **"+ New"** 按钮
2. 选择 **"Database"** → **"Add PostgreSQL"**
3. Railway 会自动创建 PostgreSQL 数据库
4. 等待数据库创建完成（约 30 秒）

✅ **完成标志**：看到 PostgreSQL 服务出现在项目列表中

#### 4.1 获取数据库连接信息

1. 点击 PostgreSQL 服务
2. 在 **"Variables"** 标签页，你会看到：
   - `PGHOST`: 数据库主机
   - `PGPORT`: 端口（通常是 5432）
   - `PGUSER`: 用户名
   - `PGPASSWORD`: 密码
   - `PGDATABASE`: 数据库名

📝 **保存这些信息**，稍后需要配置到后端服务

---

### 步骤 5: 添加 Redis 缓存（可选，2 分钟）

1. 在项目页面，点击 **"+ New"**
2. 选择 **"Database"** → **"Add Redis"**
3. 等待 Redis 创建完成

✅ **完成标志**：看到 Redis 服务出现在项目列表中

---

### 步骤 6: 配置后端环境变量（5 分钟）

1. 点击后端服务（主服务）
2. 进入 **"Variables"** 标签页
3. 点击 **"+ New Variable"** 添加以下变量：

#### 必需的环境变量

```bash
# 数据库配置（使用 Railway 提供的变量引用）
DATABASE_HOST=${{Postgres.PGHOST}}
DATABASE_PORT=${{Postgres.PGPORT}}
DATABASE_USER=${{Postgres.PGUSER}}
DATABASE_PASSWORD=${{Postgres.PGPASSWORD}}
DATABASE_NAME=${{Postgres.PGDATABASE}}

# Redis 配置（如果添加了 Redis）
REDIS_HOST=${{Redis.REDIS_HOST}}
REDIS_PORT=${{Redis.REDIS_PORT}}
REDIS_PASSWORD=${{Redis.REDIS_PASSWORD}}

# 服务器配置
SERVER_PORT=9090
SERVER_MODE=release

# JWT 配置（重要：生产环境请使用强密钥）
JWT_SECRET=your_production_jwt_secret_key_change_this
JWT_EXPIRES_HOURS=720

# CORS 配置（根据你的前端域名调整）
CORS_ALLOWED_ORIGINS=https://your-frontend-domain.com,https://your-admin-domain.com
CORS_ALLOW_CREDENTIALS=true

# Stripe 配置（如果使用）
STRIPE_SECRET_KEY=sk_test_your_stripe_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
STRIPE_PRICE_MONTHLY=price_your_monthly_price_id
STRIPE_PRICE_YEARLY=price_your_yearly_price_id

# AWS S3 配置（如果使用）
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_S3_BUCKET=your-bucket-name
```

#### 使用 Railway 变量引用（推荐）

Railway 提供了变量引用功能，可以直接引用其他服务的环境变量：

- `${{Postgres.PGHOST}}` - PostgreSQL 主机
- `${{Postgres.PGPORT}}` - PostgreSQL 端口
- `${{Postgres.PGUSER}}` - PostgreSQL 用户
- `${{Postgres.PGPASSWORD}}` - PostgreSQL 密码
- `${{Postgres.PGDATABASE}}` - PostgreSQL 数据库名
- `${{Redis.REDIS_HOST}}` - Redis 主机（如果添加了 Redis）
- `${{Redis.REDIS_PORT}}` - Redis 端口

#### 配置示例截图说明

1. 点击 **"+ New Variable"**
2. 在 **"Key"** 输入：`DATABASE_HOST`
3. 在 **"Value"** 输入：`${{Postgres.PGHOST}}`
4. 点击 **"Add"**

重复以上步骤添加所有变量。

---

### 步骤 7: 运行数据库迁移（3 分钟）

#### 方法 1: 使用 Railway CLI（推荐）

1. **安装 Railway CLI**
   ```bash
   # macOS/Linux
   curl -fsSL https://railway.app/install.sh | sh
   
   # 或使用 npm
   npm i -g @railway/cli
   ```

2. **登录 Railway**
   ```bash
   railway login
   ```

3. **链接项目**
   ```bash
   railway link
   # 选择你的项目
   ```

4. **运行迁移**
   ```bash
   # 连接到 PostgreSQL 并运行迁移
   railway run psql ${{Postgres.DATABASE_URL}} -f supabase/migrations/20240209000000_initial_schema.sql
   
   # 或者使用 Railway 的 PostgreSQL 服务
   railway connect postgres
   # 然后在 psql 中执行 SQL
   ```

#### 方法 2: 使用 Railway Web Console

1. 点击 PostgreSQL 服务
2. 点击 **"Query"** 标签页
3. 复制 `supabase/migrations/20240209000000_initial_schema.sql` 的内容
4. 粘贴到查询编辑器
5. 点击 **"Run"** 执行

#### 方法 3: 在代码中添加迁移命令

修改 `railway.json` 添加迁移步骤：

```json
{
  "deploy": {
    "startCommand": "./short-drama-api migrate && ./short-drama-api"
  }
}
```

⚠️ **注意**：确保后端代码支持迁移命令，或者手动运行一次迁移。

---

### 步骤 8: 配置服务端口和域名（2 分钟）

1. 点击后端服务
2. 进入 **"Settings"** 标签页
3. 在 **"Networking"** 部分：
   - **Port**: 设置为 `9090`（与代码中的端口一致）
   - **Public**: 开启（如果需要公开访问）

4. **生成公共域名**：
   - Railway 会自动生成一个公共域名
   - 格式：`your-service-name.up.railway.app`
   - 在 **"Networking"** 标签页可以看到

✅ **完成标志**：看到类似 `https://cursor-test-production.up.railway.app` 的域名

---

### 步骤 9: 验证部署（2 分钟）

1. **检查服务状态**
   - 在服务页面，查看 **"Metrics"** 标签页
   - 确认 CPU、内存使用正常

2. **查看日志**
   - 点击 **"Logs"** 标签页
   - 确认没有错误信息
   - 应该看到类似：`Server starting on :9090`

3. **测试 API**
   ```bash
   # 使用 Railway 提供的公共域名
   curl https://your-service-name.up.railway.app/api/health
   
   # 或测试其他端点
   curl https://your-service-name.up.railway.app/api/dramas
   ```

✅ **成功标志**：API 返回正常响应

---

### 步骤 10: 配置自定义域名（可选，5 分钟）

1. 在服务 **"Settings"** → **"Networking"**
2. 点击 **"Generate Domain"** 或 **"Custom Domain"**
3. 输入你的域名（如 `api.yourdomain.com`）
4. 按照 Railway 的提示配置 DNS：
   - 添加 CNAME 记录指向 Railway 提供的地址
   - 等待 DNS 传播（通常几分钟到几小时）

---

## 🔧 常见问题排查

### 问题 1: 构建失败 - "go: command not found"

**原因**：Railway 没有正确检测到 Dockerfile

**解决**：
- 确保根目录有 `Dockerfile` 文件
- 检查 `railway.json` 中 `builder` 设置为 `DOCKERFILE`
- 重新部署服务

### 问题 2: 数据库连接失败

**原因**：环境变量配置不正确

**解决**：
- 检查数据库变量是否正确引用：`${{Postgres.PGHOST}}`
- 确认 PostgreSQL 服务已创建并运行
- 查看后端日志确认连接错误信息

### 问题 3: 服务启动失败

**原因**：配置错误或依赖问题

**解决**：
1. 查看服务日志：**"Logs"** 标签页
2. 检查环境变量是否完整
3. 确认端口配置正确（9090）
4. 检查 `config.yaml` 或环境变量格式

### 问题 4: 迁移失败

**原因**：SQL 语法错误或权限问题

**解决**：
- 检查 SQL 文件语法
- 确认使用的是 PostgreSQL 语法（不是 MySQL）
- 使用 Railway CLI 手动运行迁移

### 问题 5: API 返回 404

**原因**：路由配置或代理设置问题

**解决**：
- 确认 API 路径正确：`/api/...`
- 检查 CORS 配置
- 查看后端日志确认路由注册

---

## 📊 监控和维护

### 查看指标

1. **Metrics 标签页**：
   - CPU 使用率
   - 内存使用
   - 网络流量
   - 请求数

2. **Logs 标签页**：
   - 实时日志
   - 错误日志
   - 访问日志

### 设置告警

1. 进入服务 **"Settings"**
2. 配置 **"Alerts"**
3. 设置 CPU、内存、错误率阈值
4. 配置通知方式（Email、Slack、Discord）

### 查看使用量

1. 在项目页面查看 **"Usage"**
2. 监控 $5/月免费额度的使用情况
3. 设置支出限制（Railway 支持硬支出限制）

---

## 💰 费用说明

### Railway 免费额度

- **$5/月免费额度**（永久）
- 500 小时运行时间/月
- 512MB RAM
- 1GB 磁盘空间

### 超出免费额度

- 按使用量付费
- 可以设置硬支出限制
- 详细价格：https://railway.app/pricing

### 优化建议

1. **使用 Railway 的休眠功能**：
   - 不活跃时自动暂停服务
   - 节省运行时间

2. **监控使用量**：
   - 定期查看 Usage 页面
   - 设置支出警报

3. **优化资源**：
   - 使用合适的实例大小
   - 优化 Docker 镜像大小

---

## 🎯 下一步

部署完成后，你可以：

1. **部署前端**：
   - 使用 Vercel/Netlify 部署前端
   - 配置 API 地址指向 Railway 后端

2. **部署管理后台**：
   - 同样使用 Vercel/Netlify
   - 或使用 Railway 部署（需要单独服务）

3. **配置 CI/CD**：
   - Railway 自动部署（GitHub push）
   - 或配置 GitHub Actions

4. **添加监控**：
   - 集成 Sentry 错误监控
   - 配置日志聚合服务

---

## 📚 相关文档

- [Railway 官方文档](https://docs.railway.app)
- [Railway Discord 社区](https://discord.gg/railway)
- [项目部署文档](./FREE_CLOUD_DEPLOYMENT.md)
- [Supabase 部署指南](./SUPABASE_DEPLOY.md)

---

## ✅ 部署检查清单

- [ ] Railway 账户已注册
- [ ] GitHub 仓库已连接
- [ ] 后端服务已部署
- [ ] PostgreSQL 数据库已创建
- [ ] Redis 缓存已添加（可选）
- [ ] 环境变量已配置
- [ ] 数据库迁移已运行
- [ ] 服务端口已配置（9090）
- [ ] 公共域名已生成
- [ ] API 测试通过
- [ ] 日志无错误
- [ ] 监控已配置

---

**🎉 恭喜！你的应用已成功部署到 Railway！**

如有问题，请查看 Railway 日志或联系 Railway 支持。
