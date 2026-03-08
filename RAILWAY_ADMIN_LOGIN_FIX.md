# Admin 登录 Network Error 修复指南

当 Admin 登录显示 "Login failed" 或 "Network error" 时，按以下步骤排查。

---

## 原因

Admin 前端需要请求**后端 API** 完成登录。常见问题：

1. **API 地址错误**：Admin 的 `VITE_API_BASE_URL` 或 `API_BASE_URL` 未指向正确的后端
2. **缺少协议**：API 地址必须为完整 URL（含 `https://`），如 `https://xxx.up.railway.app/api`。若只写 `xxx.up.railway.app/api`，请求会被当作相对路径，返回 HTML 而非 API 数据
3. **CORS 未配置**：后端未允许 Admin 域名跨域

---

## 修复步骤

### 1. 确认后端服务 URL

在 Railway 项目中找到**后端服务**（Go API），获取其公共域名，例如：
- `https://cursortest-production-xxxx.up.railway.app`（注意替换为你的实际域名）

### 2. 配置 Admin 的 API 地址

在 **Admin 服务** → **Variables** 中设置：

```bash
VITE_API_BASE_URL=https://你的后端域名/api
```

示例：
```bash
VITE_API_BASE_URL=https://cursortest-production-2b3c.up.railway.app/api
```

> 必须以 `/api` 结尾。若使用变量引用：`VITE_API_BASE_URL=https://${{Backend.RAILWAY_PUBLIC_DOMAIN}}/api`，需将 `Backend` 改为实际后端服务名。

### 3. 配置后端的 CORS

在 **后端服务** → **Variables** 中设置：

```bash
CORS_ALLOWED_ORIGINS=https://cursortest-production-1aff.up.railway.app
```

> 使用 **https**，不要用 http。域名需与 Admin 实际访问地址一致。

### 4. 重新部署

1. 修改 Admin 变量后，需**重新部署** Admin（会触发重新构建）
2. 修改后端 CORS 后，**重新部署**后端

---

## 验证

1. 打开 Admin：`https://cursortest-production-1aff.up.railway.app`
2. 打开浏览器开发者工具（F12）→ Network
3. 尝试登录
4. 查看请求：
   - 若请求发往错误地址 → 检查 `VITE_API_BASE_URL`
   - 若出现 CORS 错误 → 检查后端 `CORS_ALLOWED_ORIGINS`
   - 若请求超时/连接失败 → 检查后端是否正常运行

---

## 默认管理员

- 邮箱：`admin@example.com`
- 密码：`admin123`
