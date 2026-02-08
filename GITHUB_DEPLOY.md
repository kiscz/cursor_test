# GitHub 部署指南

本指南介绍如何使用 GitHub Actions 自动部署 Short Drama App。

## 📋 部署方案

### 方案 1: GitHub Actions + 云服务器（推荐）

适用于有云服务器（VPS、AWS EC2、DigitalOcean等）的情况。

#### 1.1 准备工作

1. **准备云服务器**
   - Ubuntu 20.04+ / Debian 11+
   - 安装 Docker 和 Docker Compose
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

2. **配置 GitHub Secrets**
   在 GitHub 仓库设置中添加以下 Secrets：
   - `DEPLOY_HOST`: 服务器 IP 地址
   - `DEPLOY_USER`: SSH 用户名（如 `root` 或 `ubuntu`）
   - `DEPLOY_SSH_KEY`: SSH 私钥（用于连接服务器）

#### 1.2 服务器端设置

```bash
# 1. 克隆仓库
git clone https://github.com/kiscz/cursor_test.git
cd cursor_test

# 2. 创建生产环境配置
cp backend/config.docker.yaml backend/config.yaml
# 编辑 config.yaml，设置生产环境配置

# 3. 创建 .env 文件（如果需要）
# 编辑 docker-compose.yml 中的环境变量

# 4. 首次启动
docker compose up -d --build
```

#### 1.3 配置 GitHub Actions

工作流文件已创建在 `.github/workflows/deploy.yml`，会自动：
- 构建 Docker 镜像
- 推送到 GitHub Container Registry
- 部署到服务器

**触发部署：**
- 推送到 `main` 分支时自动部署
- 或在 Actions 页面手动触发

### 方案 2: GitHub Actions + Docker Hub

#### 2.1 配置 Docker Hub Secrets

在 GitHub 仓库设置中添加：
- `DOCKER_USERNAME`: Docker Hub 用户名
- `DOCKER_PASSWORD`: Docker Hub 密码或访问令牌

#### 2.2 修改工作流

修改 `.github/workflows/deploy.yml`，将镜像推送到 Docker Hub：

```yaml
- name: Log in to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_PASSWORD }}
```

### 方案 3: 手动部署

#### 3.1 在服务器上手动部署

```bash
# 1. SSH 连接到服务器
ssh user@your-server.com

# 2. 克隆仓库
git clone https://github.com/kiscz/cursor_test.git
cd cursor_test

# 3. 配置环境
cp backend/config.docker.yaml backend/config.yaml
# 编辑配置文件

# 4. 启动服务
docker compose up -d --build

# 5. 查看日志
docker compose logs -f
```

#### 3.2 更新部署

```bash
cd cursor_test
git pull origin main
docker compose up -d --build
```

## 🔐 GitHub Secrets 配置

### 必需 Secrets（方案 1）

| Secret 名称 | 说明 | 示例 |
|------------|------|------|
| `DEPLOY_HOST` | 服务器 IP 或域名 | `123.45.67.89` |
| `DEPLOY_USER` | SSH 用户名 | `root` |
| `DEPLOY_SSH_KEY` | SSH 私钥 | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

### 如何获取 SSH 私钥

```bash
# 在本地生成 SSH key（如果还没有）
ssh-keygen -t ed25519 -C "github-actions"

# 复制私钥内容
cat ~/.ssh/id_ed25519

# 将公钥添加到服务器
ssh-copy-id user@your-server.com
```

## 📝 环境变量配置

### 生产环境配置

编辑 `backend/config.yaml`：

```yaml
server:
  port: 9090
  mode: release  # 生产环境使用 release

database:
  host: mysql  # Docker Compose 中使用服务名
  port: 3306
  user: root
  password: your_strong_password  # 修改为强密码
  dbname: short_drama

jwt:
  secret: your_very_strong_jwt_secret  # 必须修改！
  expires_hours: 720

stripe:
  secret_key: sk_live_xxxxx  # 生产环境使用 live key
  webhook_secret: whsec_xxxxx
  price_monthly: price_xxxxx
  price_yearly: price_xxxxx

aws:
  access_key_id: YOUR_ACCESS_KEY
  secret_access_key: YOUR_SECRET_KEY
  s3_bucket: your-bucket-name
```

## 🚀 部署流程

### 自动部署（使用 GitHub Actions）

1. **推送代码到 main 分支**
   ```bash
   git add .
   git commit -m "Update features"
   git push origin main
   ```

2. **GitHub Actions 自动执行**
   - 构建 Docker 镜像
   - 推送到容器注册表
   - SSH 连接到服务器
   - 拉取最新镜像
   - 重启服务

3. **查看部署状态**
   - 访问 GitHub Actions 页面
   - 查看部署日志

### 手动部署

```bash
# 在服务器上
cd /path/to/cursor_test
git pull origin main
docker compose pull
docker compose up -d --build
docker compose restart
```

## 🔍 验证部署

### 检查服务状态

```bash
docker compose ps
```

应该看到所有服务都在运行：
- `shortdrama-mysql`
- `shortdrama-redis`
- `shortdrama-backend`
- `shortdrama-frontend`
- `shortdrama-admin`

### 检查日志

```bash
# 所有服务日志
docker compose logs -f

# 特定服务日志
docker compose logs -f backend
docker compose logs -f frontend
```

### 访问服务

- **用户端**: http://your-server-ip
- **管理后台**: http://your-server-ip:3001
- **后端 API**: http://your-server-ip:9090/api

## 🔒 安全建议

1. **修改默认密码**
   - MySQL root 密码
   - JWT secret
   - 管理员账户密码

2. **配置防火墙**
   ```bash
   # 只开放必要端口
   sudo ufw allow 22/tcp   # SSH
   sudo ufw allow 80/tcp   # HTTP
   sudo ufw allow 443/tcp  # HTTPS
   sudo ufw enable
   ```

3. **使用 HTTPS**
   - 配置 Nginx 反向代理
   - 使用 Let's Encrypt SSL 证书

4. **定期备份数据库**
   ```bash
   docker compose exec mysql mysqldump -u root -p short_drama > backup.sql
   ```

## 📚 相关文档

- [Docker 部署指南](./DOCKER_DEPLOY.md)
- [部署文档](./DEPLOYMENT.md)
- [故障排除](./TROUBLESHOOTING.md)

## 🆘 常见问题

### Q: GitHub Actions 部署失败？

A: 检查：
1. Secrets 是否正确配置
2. 服务器 SSH 连接是否正常
3. 服务器上 Docker 是否安装
4. 查看 Actions 日志获取详细错误信息

### Q: 如何回滚到之前的版本？

```bash
# 在服务器上
cd /path/to/cursor_test
git checkout <previous-commit-hash>
docker compose up -d --build
```

### Q: 如何查看部署历史？

访问 GitHub Actions 页面，查看工作流运行历史。
