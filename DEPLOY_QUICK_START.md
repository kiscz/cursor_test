# 🚀 GitHub 部署快速开始

## 方式一：GitHub Actions 自动部署（推荐）

### 步骤 1: 配置 GitHub Secrets

1. 访问你的 GitHub 仓库：`https://github.com/kiscz/cursor_test/settings/secrets/actions`
2. 点击 "New repository secret"，添加以下三个 secrets：

| Secret 名称 | 说明 | 示例值 |
|------------|------|--------|
| `DEPLOY_HOST` | 服务器 IP 地址 | `123.45.67.89` |
| `DEPLOY_USER` | SSH 用户名 | `root` 或 `ubuntu` |
| `DEPLOY_SSH_KEY` | SSH 私钥 | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

### 步骤 2: 在服务器上准备环境

```bash
# SSH 连接到服务器
ssh user@your-server-ip

# 安装 Docker 和 Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 创建项目目录
mkdir -p /opt/shortdrama
cd /opt/shortdrama

# 克隆仓库（首次）
git clone https://github.com/kiscz/cursor_test.git .

# 创建生产配置
cp backend/config.docker.yaml backend/config.yaml
# 编辑 backend/config.yaml，修改密码和密钥

# 首次启动
docker compose up -d --build
```

### 步骤 3: 修改部署脚本中的路径

编辑 `.github/workflows/deploy.yml`，将 `/path/to/your/app` 改为你的实际路径（如 `/opt/shortdrama`）

### 步骤 4: 推送代码触发部署

```bash
git add .
git commit -m "Setup deployment"
git push origin main
```

推送后，GitHub Actions 会自动：
1. 构建 Docker 镜像
2. 推送到 GitHub Container Registry
3. SSH 连接到服务器
4. 拉取最新代码和镜像
5. 重启服务

## 方式二：手动部署

### 在服务器上执行

```bash
# 1. 克隆仓库
git clone https://github.com/kiscz/cursor_test.git
cd cursor_test

# 2. 配置环境
cp backend/config.docker.yaml backend/config.yaml
# 编辑 backend/config.yaml

# 3. 启动服务
docker compose up -d --build

# 4. 查看状态
docker compose ps
docker compose logs -f
```

### 更新部署

```bash
cd cursor_test
git pull origin main
docker compose up -d --build
```

## 🔑 获取 SSH 私钥

如果还没有 SSH key，在本地生成：

```bash
# 生成 SSH key
ssh-keygen -t ed25519 -C "github-deploy"

# 查看私钥（复制到 GitHub Secrets）
cat ~/.ssh/id_ed25519

# 将公钥添加到服务器
ssh-copy-id user@your-server-ip
# 或者手动添加
cat ~/.ssh/id_ed25519.pub
# 然后添加到服务器的 ~/.ssh/authorized_keys
```

## 📋 检查清单

- [ ] GitHub Secrets 已配置（DEPLOY_HOST, DEPLOY_USER, DEPLOY_SSH_KEY）
- [ ] 服务器已安装 Docker 和 Docker Compose
- [ ] 服务器可以 SSH 连接
- [ ] 服务器上已克隆仓库
- [ ] 生产配置文件已创建并修改
- [ ] 部署脚本中的路径已更新

## 🎯 访问服务

部署成功后：
- **用户端**: http://your-server-ip
- **管理后台**: http://your-server-ip:3001
- **API**: http://your-server-ip:9090/api

## 📚 详细文档

查看 [GITHUB_DEPLOY.md](./GITHUB_DEPLOY.md) 获取更详细的部署说明。
