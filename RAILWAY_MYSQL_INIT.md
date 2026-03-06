# Railway 上 MySQL 初始化指南

本文档说明如何在 Railway 上使用 MySQL 并完成数据库初始化。

---

## 一、添加 MySQL 服务

Railway 支持 MySQL 模板，按以下步骤添加：

1. 在 Railway 项目中点击 **"+ New"**
2. 选择 **"Database"** → **"Add MySQL"**（或从模板市场选择 MySQL）
3. 等待 MySQL 创建完成

> 若项目里没有 MySQL 选项，可访问 https://railway.app/template/mysql 从模板部署。

---

## 二、创建数据库

Railway MySQL 默认可能没有 `short_drama` 库，需要先创建：

### 方法 A：Railway Web Console（推荐）

1. 点击 MySQL 服务
2. 进入 **"Data"** 或 **"Query"** 标签页
3. 执行：
   ```sql
   CREATE DATABASE IF NOT EXISTS short_drama CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

### 方法 B：Railway CLI

```bash
# 安装 Railway CLI
npm i -g @railway/cli

# 登录并链接项目
railway login
railway link

# 连接 MySQL 并创建数据库
railway connect mysql
# 在 mysql> 提示符下执行：
# CREATE DATABASE IF NOT EXISTS short_drama CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
# exit;
```

---

## 三、执行 Schema 迁移

### 方法 A：Railway Web Console（推荐，一键执行）

1. 点击 MySQL 服务 → **"Query"** 标签
2. 复制 `database/schema-railway.sql` 的**全部内容**（已包含建库和 `USE short_drama`）
3. 粘贴到查询编辑器
4. 点击 **"Run"** 执行

> 若使用 `database/schema.sql`，需在开头手动加上 `USE short_drama;`

### 方法 B：Railway CLI + 本地 mysql 客户端

```bash
# 获取 MySQL 连接信息（在 Railway MySQL 服务的 Variables 中查看）
# MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE

# 使用 mysql 客户端执行（需本地安装 mysql-client）
mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD short_drama < database/schema.sql
```

### 方法 C：使用 Railway run 执行

```bash
railway run bash -c 'mysql -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD short_drama < database/schema.sql'
```

---

## 四、配置后端环境变量

在后端服务的 **Variables** 中添加：

### 使用 Railway MySQL 变量引用（推荐）

```bash
# 数据库（引用 Railway MySQL 服务的变量）
DATABASE_HOST=${{MySQL.MYSQL_HOST}}
DATABASE_PORT=${{MySQL.MYSQL_PORT}}
DATABASE_USER=root
# 使用 root 时，密码用 MYSQL_ROOT_PASSWORD（若存在）或 MYSQL_PASSWORD
DATABASE_PASSWORD=${{MySQL.MYSQL_ROOT_PASSWORD}}
# 若上面不存在，改用：DATABASE_PASSWORD=${{MySQL.MYSQL_PASSWORD}}
DATABASE_NAME=short_drama

# 或使用 MYSQL_*（后端已支持 MYSQL_ROOT_PASSWORD）
# MYSQL_HOST=${{MySQL.MYSQL_HOST}}
# MYSQL_PORT=${{MySQL.MYSQL_PORT}}
# ... 同上

# 使用 MySQL（重要！）
USE_POSTGRES=false

# 服务器
SERVER_PORT=9090
SERVER_MODE=release

# JWT（生产环境务必更换）
JWT_SECRET=你的强密钥至少32字符

# Redis（使用 Railway Redis 时，详见 RAILWAY_REDIS_CONFIG.md）
REDIS_URL=${{Redis.REDIS_URL}}

# 或分项配置：
# REDIS_HOST=${{Redis.REDIS_HOST}}
# REDIS_PORT=${{Redis.REDIS_PORT}}
# REDIS_PASSWORD=${{Redis.REDIS_PASSWORD}}

# 不使用 Redis 时
# USE_REDIS=false

# CORS
CORS_ALLOWED_ORIGINS=https://你的前端域名
CORS_ALLOW_CREDENTIALS=true
```

> **注意**：Railway MySQL 的变量名可能是 `MYSQL_HOST`、`MYSQL_PRIVATE_URL` 等，请在 MySQL 服务的 Variables 中确认实际名称。

---

## 五、确认数据库名

Railway MySQL 模板默认数据库名可能是 `railway` 或 `mysql`。若与 `short_drama` 不同，有两种做法：

1. **创建 `short_drama` 库**（见上文「二、创建数据库」）
2. **或** 将 `DATABASE_NAME` / `MYSQL_DATABASE` 设为 Railway 提供的默认库名，并在该库中执行 `database/schema.sql`

---

## 六、验证

1. 重新部署后端服务
2. 查看 **Logs**，应看到 `Server starting on :9090`
3. 测试 API：
   ```bash
   curl https://你的服务.up.railway.app/api/health
   curl https://你的服务.up.railway.app/api/dramas
   ```

---

## 七、默认管理员账号

`schema.sql` 中已插入默认管理员：

- **邮箱**：`admin@example.com`
- **密码**：`admin123`

**生产环境请尽快修改密码。**

---

## 八、常见问题

**Q: Railway 没有 MySQL 选项？**  
A: 从模板市场添加：https://railway.app/template/mysql

**Q: 变量引用 `${{MySQL.MYSQL_HOST}}` 不生效？**  
A: 确认 MySQL 服务名称，变量引用格式为 `${{服务名.变量名}}`，服务名需与项目内显示一致。

**Q: 连接被拒绝？**  
A: 检查 MySQL 是否已启动，以及 `DATABASE_HOST` 是否使用 Railway 内部地址（如 `mysql.railway.internal`）。

**Q: 表已存在错误？**  
A: `schema.sql` 使用 `CREATE TABLE IF NOT EXISTS`，重复执行不会报错；如需重建，先 `DROP DATABASE short_drama` 再重新执行。

---

## 相关文档

- [RAILWAY_MYSQL_CONFIG.md](./RAILWAY_MYSQL_CONFIG.md) - MySQL 详细配置
- [RAILWAY_REDIS_CONFIG.md](./RAILWAY_REDIS_CONFIG.md) - Redis 配置
- [RAILWAY_QUICK_START.md](./RAILWAY_QUICK_START.md) - Railway 快速开始
