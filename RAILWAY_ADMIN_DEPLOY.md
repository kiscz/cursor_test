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
4. **Root Directory**：设为 `admin`，或留空（使用根目录的 `Dockerfile.railway`）

### 2. 配置变量

在 Admin 服务的 **Variables** 中添加：

```bash
# 推荐：后端地址（不含 /api），Admin 会代理 /api 到此后端，无 CORS 问题
BACKEND_URL=https://${{Backend.RAILWAY_PUBLIC_DOMAIN}}

# 若 Railway 未自动使用 Dockerfile.railway，手动指定
RAILWAY_DOCKERFILE_PATH=Dockerfile.railway
```

> 将 `Backend` 替换为你的后端服务名。示例：`BACKEND_URL=https://incredible-balance-production-791d.up.railway.app`
>
> 设置 `BACKEND_URL` 后，Admin 会将 `/api` 请求代理到后端，前端使用同源 `/api`，**无需配置 CORS**。

### 3. 配置端口与域名

1. 点击 Admin 服务 → **Settings** → **Networking**
2. **Port**：设为 `8080`（与 Railway 默认 PORT 一致，若未显示则无需修改）
3. 点击 **Generate Domain**，获得类似 `admin-xxx.up.railway.app` 的域名

### 4. 部署

Railway 会使用 `admin/Dockerfile.railway`（Node 内置 http 服务，直接读取 `PORT`），开始构建并部署。

---

## 变量说明

| 变量 | 说明 |
|------|------|
| `BACKEND_URL` | **推荐**。后端地址（不含 `/api`），如 `https://xxx.up.railway.app`。Admin 会代理 `/api` 到此后端，无 CORS。 |
| `API_BASE_URL` | 备选，直连后端时用，需同时配置后端 CORS |
| `VITE_API_BASE_URL` | 可选，构建时备用 |
| `RAILWAY_DOCKERFILE_PATH` | 可选，若未自动检测则设为 `Dockerfile.railway` |

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
A: 使用 `BACKEND_URL` 代理方案（推荐，无 CORS）。若直连后端，需配置 `CORS_ALLOWED_ORIGINS`。详见 [RAILWAY_ADMIN_LOGIN_FIX.md](./RAILWAY_ADMIN_LOGIN_FIX.md)

**Q: 构建失败？**  
A: 确认 Root Directory 已设为 `admin`，Railway 会从 `admin/` 目录构建。

**Q: 变量引用不生效？**  
A: 服务名区分大小写，需与 Railway 项目内显示完全一致。

**Q: 登录失败 Network error？**  
A: 见 [RAILWAY_ADMIN_LOGIN_FIX.md](./RAILWAY_ADMIN_LOGIN_FIX.md)

**Q: 502 Bad Gateway？**  
A: 检查以下几点：
1. **Root Directory** 必须设为 `admin`
2. 在 Admin 服务 Variables 中添加 `RAILWAY_DOCKERFILE_PATH=Dockerfile.railway`（若 Railway 未自动检测）
3. **Settings → Networking** 中确认 **Port** 为 `8080` 或与 Railway 的 `PORT` 一致
4. 查看 **Deploy Logs** 确认构建成功、服务已启动
