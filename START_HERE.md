# 🚀 开始部署 - START HERE

选择最适合你的部署方式：

---

## ⚡ 方式一：Docker部署（推荐，最简单）

**优点**: 一键启动，无需安装其他软件，环境隔离

### 步骤：

1. **安装Docker Desktop**
   ```bash
   # 访问官网下载安装
   https://www.docker.com/products/docker-desktop
   
   # 或使用Homebrew
   brew install --cask docker
   ```

2. **启动Docker Desktop应用**（等待启动完成）

3. **运行部署脚本**
   ```bash
   cd /Users/kis/data/cursor_test
   ./quick-start.sh
   ```

4. **访问应用**
   - 用户App: http://localhost:80
   - 后端API: http://localhost:8080
   - 管理后台: http://localhost:3001

**就这么简单！** 🎉

---

## 🛠️ 方式二：本地开发环境部署

**优点**: 直接运行，方便开发调试

### 步骤：

1. **安装依赖软件**（需要网络权限）
   ```bash
   cd /Users/kis/data/cursor_test
   ./install-dependencies.sh
   ```
   
   这会自动安装：
   - Node.js 18
   - Go 1.21
   - MySQL 8
   - Redis

2. **配置MySQL密码**
   ```bash
   mysql_secure_installation
   ```

3. **创建数据库**
   ```bash
   mysql -u root -p
   # 输入密码后执行：
   CREATE DATABASE short_drama;
   exit
   
   # 导入schema
   mysql -u root -p short_drama < database/schema.sql
   ```

4. **配置后端**
   ```bash
   cd backend
   cp config.example.yaml config.yaml
   nano config.yaml  # 编辑数据库密码
   ```

5. **启动所有服务**
   ```bash
   cd /Users/kis/data/cursor_test
   ./setup-dev.sh
   ```

6. **访问应用**
   - 用户App: http://localhost:3000
   - 后端API: http://localhost:8080
   - 管理后台: http://localhost:3001

---

## 🎯 默认登录信息

**管理后台登录**:
- 邮箱: `admin@example.com`
- 密码: `admin123`

---

## 📝 快速命令参考

### Docker方式
```bash
# 启动所有服务
./quick-start.sh

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 重启服务
docker-compose restart
```

### 本地开发方式
```bash
# 启动所有服务
./setup-dev.sh

# 停止：按 Ctrl+C

# 单独启动后端
cd backend && go run main.go

# 单独启动前端
cd frontend && npm run dev

# 单独启动管理后台
cd admin && npm run dev
```

---

## ❓ 常见问题

### Docker方式

**Q: Docker命令需要sudo？**
```bash
# 将当前用户加入docker组
sudo usermod -aG docker $USER
# 重新登录生效
```

**Q: 端口被占用？**
```bash
# 检查端口占用
lsof -i :80
lsof -i :8080
lsof -i :3001

# 停止占用的进程或修改docker-compose.yml中的端口
```

### 本地开发方式

**Q: MySQL连接失败？**
```bash
# 检查MySQL是否运行
brew services list

# 启动MySQL
brew services start mysql

# 重置密码
mysql -u root -p
```

**Q: Go版本太旧？**
```bash
# 卸载旧版本
brew uninstall go

# 安装新版本
brew install go

# 验证版本
go version  # 应该是 1.21+
```

**Q: Node.js版本太旧？**
```bash
# 安装新版本
brew install node@18
brew link --overwrite node@18

# 验证版本
node --version  # 应该是 v18+
```

---

## 🎉 下一步

部署成功后：

1. **测试用户App**
   - 访问 http://localhost:3000
   - 浏览剧集
   - 注册账号

2. **登录管理后台**
   - 访问 http://localhost:3001
   - 使用默认账号登录
   - 添加剧集内容

3. **阅读文档**
   - `FEATURES.md` - 查看所有功能
   - `DEPLOYMENT.md` - 生产环境部署
   - `SETUP_GUIDE.md` - 详细设置指南

---

## 📞 需要帮助？

- 查看错误日志
- 阅读相关文档
- 检查端口是否被占用
- 确认所有服务都在运行

**祝部署顺利！** 🚀
