# Admin 登录 Network Error 修复指南

当 Admin 登录显示 "Login failed" 或 "Network error - check API URL and CORS" 时，按以下步骤排查。

---

## 推荐方案：代理（无 CORS 问题）

Admin 的 `server.js` 支持将 `/api` 代理到后端，前端请求同源 `/api`，**无需配置 CORS**。

### 1. 在 Admin 服务设置环境变量

在 **Admin 服务** → **Variables** 中添加：

```bash
BACKEND_URL=https://你的后端域名
```

示例（替换为你的后端 Railway 域名）：
```bash
BACKEND_URL=https://cursortest-production-2b3c.up.railway.app
```

或使用 Railway 变量引用：
```bash
BACKEND_URL=https://${{Backend.RAILWAY_PUBLIC_DOMAIN}}
```

> 不要以 `/api` 结尾，服务会自动拼接。

### 2. 重新部署 Admin

保存变量后，Railway 会自动重新部署。部署完成后，`/config.json` 会返回 `apiBaseUrl: "/api"`，前端请求同源，由 Admin 代理到后端。

---

## 备选方案：直连后端（需配置 CORS）

若 Admin 直接请求后端 URL（如 `https://incredible-balance-production-791d.up.railway.app/api`），必须在**后端**配置 CORS。

### 1. 后端 CORS 变量（必填）

在 **Backend 服务** → **Variables** 中添加：

```bash
CORS_ALLOWED_ORIGINS=https://cursortest-production-1aff.up.railway.app
```

> 将 `cursortest-production-1aff.up.railway.app` 替换为你的 **Admin 实际访问域名**（不含路径）。多个域名用逗号分隔。

### 2. Admin 变量（若使用直连）

```bash
VITE_API_BASE_URL=https://incredible-balance-production-791d.up.railway.app/api
```

### 3. 重新部署 Backend 与 Admin

---

## 验证

1. 打开 Admin 页面
2. F12 → Network，尝试登录
3. 查看 `/api/admin/auth/login` 请求：
   - 若为代理：请求发往 Admin 同源，状态 200 或 4xx
   - 若为直连：请求发往后端域名，需无 CORS 报错

---

## 默认管理员

- 邮箱：`admin@example.com`
- 密码：`admin123`
