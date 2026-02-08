# 🐳 Docker Desktop 安装指南

## 方式一：直接下载安装（推荐，最简单）

1. **下载Docker Desktop**
   
   访问官网下载：https://www.docker.com/products/docker-desktop
   
   或点击直接下载：
   - Apple Silicon (M1/M2): https://desktop.docker.com/mac/main/arm64/Docker.dmg
   - Intel芯片: https://desktop.docker.com/mac/main/amd64/Docker.dmg

2. **安装**
   - 打开下载的 `Docker.dmg` 文件
   - 将 Docker 图标拖到 Applications 文件夹
   - 双击 Applications 中的 Docker 启动

3. **首次启动**
   - 需要输入管理员密码
   - 等待 Docker 启动完成（菜单栏图标不再转动）
   - 同意服务条款

4. **验证安装**
   ```bash
   docker --version
   docker-compose --version
   ```

---

## 方式二：使用Homebrew安装

```bash
# 安装（需要输入密码）
brew install --cask docker

# 启动 Docker Desktop
open /Applications/Docker.app

# 等待启动完成后验证
docker --version
```

---

## 安装完成后

Docker Desktop 启动完成后，运行部署脚本：

```bash
cd /Users/kis/data/cursor_test
./quick-start.sh
```

---

## 故障排除

### Docker命令不可用
```bash
# 确保Docker Desktop正在运行
# 检查菜单栏是否有Docker图标

# 添加到PATH（如果需要）
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
```

### 权限问题
```bash
# 将当前用户添加到docker组
sudo dscl . -append /Groups/docker GroupMembership $(whoami)
```
