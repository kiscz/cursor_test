# Railway 管理后台 (Admin) 部署指南

将 Short Drama 管理后台部署到 Railway。

---

## 前置条件

- 后端服务已部署到 Railway
- 后端已生成公共域名（如 `xxx.up.railway.app`）

---

## 部署步骤

### 1. 添加 Admin 服务

1. 在 Railway 项目中点击 **"+ New"**
2. 选择 **"GitHub Repo"**（若未添加则先连接仓库）
3. 选择同一仓库
4. **重要**：在配置中设置 **Root Directory** 为 `admin`

### 2. 配置构建变量

在 Admin 服务的 **Variables** 中添加（构建时生效）：

```bash
# 后端 API 地址（将 Backend 替换为你的后端服务名）
VITE_API_BASE_URL=https://${{Backend.RAILWAY_PUBLIC_DOMAIN}}/api
```

> 若后端服务名为 `cursor_test` 或 `shortdrama-backend`，则改为：
> `VITE_API_BASE_URL=https://${{cursor_test.RAILWAY_PUBLIC_DOMAIN}}/api`

### 3. 生成公共域名

1. 点击 Admin 服务 → **Settings** → **Networking**
2. 点击 **Generate Domain**
3. 获得类似 `admin-xxx.up.railway.app` 的域名

### 4. 部署

Railway 会使用 `admin/Dockerfile.railway`（基于 serve，自动支持 PORT），开始构建并部署。

---

## 变量说明

| 变量 | 说明 |
|------|------|
| `VITE_API_BASE_URL` | 后端 API 完整地址，必须以 `/api` 结尾 |

---

## 服务名引用

Railway 变量引用格式为 `${{服务名.变量名}}`，服务名需与项目内显示一致：

- 在项目页查看后端服务名称
- 常见名称：`Backend`、`backend`、`cursor_test`、仓库名等

---

## 验证

1. 访问 Admin 域名，应看到登录页
2. 使用默认管理员登录：`admin@example.com` / `admin123`
3. 若能正常进入后台，说明 API 连接正常

---

## 常见问题

**Q: 登录后白屏或 API 报错？**  
A: 检查 `VITE_API_BASE_URL` 是否正确，且后端 CORS 已配置 Admin 域名：
```bash
CORS_ALLOWED_ORIGINS=https://admin-xxx.up.railway.app
```

**Q: 构建失败？**  
A: 确认 Root Directory 已设为 `admin`，Railway 会从 `admin/` 目录构建。

**Q: 变量引用不生效？**  
A: 服务名区分大小写，需与 Railway 项目内显示完全一致。
