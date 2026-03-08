# Railway 前端 (Frontend) 部署指南

将 Short Drama 用户端前端部署到 Railway。

---

## 前置条件

- 后端服务已部署到 Railway
- 后端已生成公共域名（如 `xxx.up.railway.app`）

---

## 部署步骤

### 1. 添加 Frontend 服务

1. 在 Railway 项目中点击 **"+ New"**
2. 选择 **"GitHub Repo"**（若未添加则先连接仓库）
3. 选择同一仓库
4. **Root Directory**：设为 `frontend`

### 2. 配置变量

在 Frontend 服务的 **Variables** 中添加：

```bash
# 推荐：后端地址（不含 /api），Frontend 会代理 /api 到此后端，无 CORS 问题
BACKEND_URL=https://${{Backend.RAILWAY_PUBLIC_DOMAIN}}

# 若 Railway 未自动使用 Dockerfile.railway，手动指定
RAILWAY_DOCKERFILE_PATH=Dockerfile.railway
```

> 将 `Backend` 替换为你的后端服务名。示例：`BACKEND_URL=https://incredible-balance-production-791d.up.railway.app`
>
> 设置 `BACKEND_URL` 后，Frontend 会将 `/api` 请求代理到后端，前端使用同源 `/api`，**无需配置 CORS**。

### 3. 配置端口与域名

1. 点击 Frontend 服务 → **Settings** → **Networking**
2. **Port**：设为 `8080`（与 Railway 默认 PORT 一致，若未显示则无需修改）
3. 点击 **Generate Domain**，获得类似 `frontend-xxx.up.railway.app` 的域名

### 4. 部署

Railway 会使用 `frontend/Dockerfile.railway`（Node 内置 http 服务，直接读取 `PORT`），开始构建并部署。

---

## 变量说明

| 变量 | 说明 |
|------|------|
| `BACKEND_URL` | **推荐**。后端地址（不含 `/api`），如 `https://xxx.up.railway.app`。Frontend 会代理 `/api` 到此后端，无 CORS。 |
| `API_BASE_URL` | 备选，直连后端时用，需同时配置后端 CORS |
| `VITE_API_BASE_URL` | 可选，构建时备用 |
| `RAILWAY_DOCKERFILE_PATH` | 可选，若未自动检测则设为 `Dockerfile.railway` |

---

## 服务名引用

Railway 变量引用格式为 `${{服务名.变量名}}`，服务名需与项目内显示一致：

- 在项目页查看后端服务名称
- 常见名称：`Backend`、`backend`、`incredible-balance-production-791d` 等

---

## 验证

1. 访问 Frontend 域名，应看到 Short Drama 首页
2. 可浏览剧集、登录、注册
3. 若 API 请求正常，说明代理配置正确

---

## 常见问题

**Q: 页面空白或 API 报错？**  
A: 使用 `BACKEND_URL` 代理方案（推荐，无 CORS）。若直连后端，需在 Backend 配置 `CORS_ALLOWED_ORIGINS` 包含 Frontend 域名。

**Q: 构建失败？**  
A: 确认 Root Directory 已设为 `frontend`，Railway 会从 `frontend/` 目录构建。

**Q: 502 Bad Gateway（访问 /api/* 时）？**  
A: 通常是代理无法连接后端，请检查：
1. **BACKEND_URL** 是否已设置且正确（如 `https://incredible-balance-production-791d.up.railway.app`）
2. 后端服务是否正常运行（访问 `https://后端域名/health` 应返回 200）
3. 查看 Frontend 的 Deploy Logs，确认启动时有 `API proxy enabled: /api -> https://...` 日志
4. Railway 变量引用 `${{Backend.RAILWAY_PUBLIC_DOMAIN}}` 中的服务名需与项目内后端服务名完全一致
