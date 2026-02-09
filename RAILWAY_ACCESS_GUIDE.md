# Railway 部署后访问指南

部署完成后，本指南将告诉你如何访问和测试你的应用。

---

## 🌐 获取访问地址

### 1. 后端 API 地址

#### 在 Railway Dashboard 中查看

1. 登录 Railway：https://railway.app
2. 进入你的项目
3. 点击后端服务（主服务）
4. 进入 **"Settings"** → **"Networking"** 标签页
5. 你会看到：
   - **Public Domain**：类似 `your-service-name.up.railway.app`
   - **Port**：应该是 `9090`

#### API 基础 URL

```
https://your-service-name.up.railway.app
```

**注意**：Railway 会自动提供 HTTPS，无需额外配置。

---

## 🧪 测试后端 API

### 方法 1: 使用浏览器

直接在浏览器中访问：

```
https://your-service-name.up.railway.app/api/health
```

如果配置了健康检查端点，应该返回 JSON 响应。

### 方法 2: 使用 curl

```bash
# 测试健康检查
curl https://your-service-name.up.railway.app/api/health

# 测试获取剧集列表（可能需要认证）
curl https://your-service-name.up.railway.app/api/dramas

# 测试用户注册
curl -X POST https://your-service-name.up.railway.app/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123456",
    "username": "testuser"
  }'
```

### 方法 3: 使用 Postman 或 Insomnia

1. 创建新请求
2. URL: `https://your-service-name.up.railway.app/api/...`
3. 选择请求方法（GET、POST 等）
4. 添加 Headers（如需要）：
   ```
   Content-Type: application/json
   Authorization: Bearer your_token_here
   ```
5. 发送请求

---

## 📱 前端应用访问

### 部署前端到 Vercel/Netlify

#### 1. 部署到 Vercel（推荐）

```bash
# 安装 Vercel CLI
npm i -g vercel

# 在 frontend 目录
cd frontend
vercel

# 按照提示配置：
# - 项目名称
# - 是否覆盖现有项目
# - 环境变量配置
```

#### 2. 配置环境变量

在 Vercel Dashboard → Project Settings → Environment Variables：

```bash
VITE_API_BASE_URL=https://your-service-name.up.railway.app/api
```

#### 3. 重新部署

Vercel 会自动重新部署，或手动触发：

```bash
vercel --prod
```

#### 4. 访问前端

Vercel 会提供类似 `your-app.vercel.app` 的地址。

---

### 部署前端到 Netlify

#### 1. 连接 GitHub 仓库

1. 登录 Netlify：https://netlify.com
2. 点击 **"Add new site"** → **"Import an existing project"**
3. 选择 GitHub，授权并选择仓库
4. 配置构建设置：
   - **Base directory**: `frontend`
   - **Build command**: `npm run build`
   - **Publish directory**: `frontend/dist`

#### 2. 配置环境变量

在 Netlify Dashboard → Site settings → Environment variables：

```bash
VITE_API_BASE_URL=https://your-service-name.up.railway.app/api
```

#### 3. 部署

Netlify 会自动部署，或手动触发 **"Deploy site"**。

#### 4. 访问前端

Netlify 会提供类似 `your-app.netlify.app` 的地址。

---

## 🖥️ 管理后台访问

### 部署管理后台

管理后台（admin）可以部署到：

1. **Vercel**（推荐）
2. **Netlify**
3. **Railway**（单独服务）

#### 部署到 Vercel

```bash
cd admin
vercel
```

配置环境变量：
```bash
VITE_API_BASE_URL=https://your-service-name.up.railway.app/api
```

#### 部署到 Railway（作为单独服务）

1. 在 Railway 项目中点击 **"+ New"**
2. 选择 **"GitHub Repo"**
3. 选择同一个仓库
4. Railway 会自动检测到 `admin` 目录
5. 配置环境变量：
   ```bash
   VITE_API_BASE_URL=https://your-service-name.up.railway.app/api
   ```
6. 部署完成后，Railway 会提供管理后台的访问地址

---

## 🔐 配置 CORS（重要！）

### 在后端环境变量中配置

在 Railway 后端服务的 **Variables** 中添加：

```bash
# 允许的前端域名（用逗号分隔）
CORS_ALLOWED_ORIGINS=https://your-frontend.vercel.app,https://your-admin.vercel.app,https://your-frontend.netlify.app
CORS_ALLOW_CREDENTIALS=true
```

**重要**：
- 必须包含 `https://` 协议
- 多个域名用逗号分隔，不要有空格
- 如果前端在本地开发，也需要添加 `http://localhost:3000`

---

## 📊 查看服务状态和日志

### 在 Railway Dashboard

1. **查看服务状态**：
   - 进入服务页面
   - 查看 **"Metrics"** 标签页
   - 查看 CPU、内存、网络使用情况

2. **查看日志**：
   - 点击 **"Logs"** 标签页
   - 实时查看应用日志
   - 搜索错误信息

3. **查看部署历史**：
   - 点击 **"Deployments"** 标签页
   - 查看所有部署记录
   - 点击某个部署查看详细日志

---

## 🔍 常见访问问题排查

### 问题 1: 502 Bad Gateway

**原因**：服务未启动或崩溃

**解决**：
1. 查看 Railway Logs，检查错误信息
2. 确认环境变量配置正确
3. 检查数据库连接是否正常
4. 确认端口配置正确（9090）

### 问题 2: CORS 错误

**错误信息**：
```
Access to fetch at 'https://...' from origin 'https://...' has been blocked by CORS policy
```

**解决**：
1. 在后端环境变量中添加前端域名到 `CORS_ALLOWED_ORIGINS`
2. 确保 `CORS_ALLOW_CREDENTIALS=true`
3. 重新部署后端服务

### 问题 3: 404 Not Found

**原因**：API 路径不正确

**解决**：
1. 确认 API 路径包含 `/api` 前缀
2. 检查路由配置是否正确
3. 查看后端日志确认路由注册

### 问题 4: 401 Unauthorized

**原因**：需要认证但未提供 token

**解决**：
1. 先注册/登录获取 token
2. 在请求头中添加：
   ```
   Authorization: Bearer your_token_here
   ```

### 问题 5: 数据库连接失败

**原因**：数据库配置错误

**解决**：
1. 检查数据库环境变量是否正确
2. 确认数据库服务已启动
3. 查看后端日志中的数据库连接错误

---

## 🎯 完整访问流程示例

### 1. 获取后端地址

```
后端 API: https://short-drama-api.up.railway.app
```

### 2. 测试后端

```bash
# 健康检查
curl https://short-drama-api.up.railway.app/api/health

# 注册用户
curl -X POST https://short-drama-api.up.railway.app/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","username":"test"}'

# 登录获取 token
curl -X POST https://short-drama-api.up.railway.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

### 3. 配置前端

在 Vercel/Netlify 环境变量中设置：
```bash
VITE_API_BASE_URL=https://short-drama-api.up.railway.app/api
```

### 4. 配置后端 CORS

在 Railway 后端环境变量中设置：
```bash
CORS_ALLOWED_ORIGINS=https://your-frontend.vercel.app,https://your-admin.vercel.app
CORS_ALLOW_CREDENTIALS=true
```

### 5. 访问前端

```
前端: https://your-frontend.vercel.app
管理后台: https://your-admin.vercel.app
```

---

## 📱 移动端访问

### 如果使用 Capacitor（移动应用）

1. **配置 API 地址**：
   - 在 `frontend/src/utils/request.js` 中配置
   - 或使用环境变量 `VITE_API_BASE_URL`

2. **构建移动应用**：
   ```bash
   cd frontend
   npm run build
   npx cap sync
   npx cap open android  # 或 ios
   ```

3. **在 Android Studio/Xcode 中构建 APK/IPA**

---

## 🔗 自定义域名配置

### 后端自定义域名

1. 在 Railway 服务 **Settings** → **Networking**
2. 点击 **"Custom Domain"**
3. 输入你的域名（如 `api.yourdomain.com`）
4. 按照 Railway 提示配置 DNS：
   - 添加 CNAME 记录指向 Railway 提供的地址
   - 等待 DNS 传播（几分钟到几小时）

### 前端自定义域名

#### Vercel
1. Project Settings → Domains
2. 添加你的域名
3. 配置 DNS 记录

#### Netlify
1. Site settings → Domain management
2. 添加自定义域名
3. 配置 DNS 记录

---

## ✅ 访问检查清单

- [ ] 后端服务已部署并运行
- [ ] 获取后端公共域名
- [ ] 测试后端 API（健康检查）
- [ ] 前端已部署到 Vercel/Netlify
- [ ] 前端环境变量已配置（`VITE_API_BASE_URL`）
- [ ] 后端 CORS 已配置（包含前端域名）
- [ ] 测试前端可以访问后端 API
- [ ] 管理后台已部署
- [ ] 管理后台环境变量已配置
- [ ] 测试完整功能（注册、登录、浏览剧集等）

---

## 🎉 完成！

现在你的应用应该可以正常访问了：

- **后端 API**: `https://your-service.up.railway.app`
- **前端应用**: `https://your-frontend.vercel.app`
- **管理后台**: `https://your-admin.vercel.app`

如有问题，查看 Railway Logs 或联系支持。
