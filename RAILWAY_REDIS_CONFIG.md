# Railway Redis 配置指南

本文档说明如何在 Railway 上添加并配置 Redis，供后端服务使用。

---

## 一、添加 Redis 服务

1. 在 Railway 项目中点击 **"+ New"**
2. 选择 **"Database"** → **"Add Redis"**
3. 等待 Redis 创建完成

> 若没有 Redis 选项，可访问 https://railway.app/template/redis 从模板部署。

---

## 二、配置后端环境变量

在后端服务的 **Variables** 中添加 Redis 相关变量。

### 方式 A：使用 REDIS_URL（推荐）

Railway Redis 提供完整的连接 URL，后端已支持直接解析：

```bash
# 引用 Railway Redis 的 REDIS_URL（服务名以实际为准，如 Redis）
REDIS_URL=${{Redis.REDIS_URL}}

# 确保启用 Redis（默认启用，不设置 USE_REDIS=false 即可）
# USE_REDIS=true   # 可选，不写即默认启用
```

### 方式 B：使用分项变量

```bash
REDIS_HOST=${{Redis.REDIS_HOST}}
REDIS_PORT=${{Redis.REDIS_PORT}}
REDIS_PASSWORD=${{Redis.REDIS_PASSWORD}}
```

> 变量引用格式为 `${{服务名.变量名}}`，服务名需与项目内 Redis 服务显示的名称一致（如 `Redis`、`redis`）。

---

## 三、Railway Redis 提供的变量

| 变量名 | 说明 |
|--------|------|
| `REDIS_URL` | 完整连接 URL（推荐使用） |
| `REDIS_HOST` | Redis 主机（内部为 `xxx.railway.internal`） |
| `REDIS_PORT` | 端口（通常 6379） |
| `REDIS_PASSWORD` | 密码 |
| `REDIS_USER` | 用户名（Redis 6+ ACL） |

---

## 四、与 MySQL/PostgreSQL 一起使用

若同时使用 MySQL 和 Redis，后端 Variables 示例：

```bash
# MySQL
DATABASE_HOST=${{MySQL.MYSQL_HOST}}
DATABASE_PORT=${{MySQL.MYSQL_PORT}}
DATABASE_USER=${{MySQL.MYSQL_USER}}
DATABASE_PASSWORD=${{MySQL.MYSQL_PASSWORD}}
DATABASE_NAME=short_drama
USE_POSTGRES=false

# Redis
REDIS_URL=${{Redis.REDIS_URL}}

# 其他
SERVER_PORT=9090
JWT_SECRET=你的强密钥
CORS_ALLOWED_ORIGINS=https://你的前端域名
```

---

## 五、不使用 Redis 时

若暂不添加 Redis，设置：

```bash
USE_REDIS=false
```

后端会跳过 Redis 初始化，服务可正常启动（部分缓存功能不可用）。

---

## 六、验证连接

1. 添加 Redis 变量后重新部署后端
2. 查看 **Logs**，应看到 `Server starting on :9090`，无 Redis 连接错误
3. 若连接失败，检查：
   - Redis 服务是否已启动
   - 变量引用格式是否正确（`${{Redis.REDIS_URL}}`）
   - 服务名是否与项目内一致

---

## 七、常见问题

**Q: 变量引用 `${{Redis.REDIS_URL}}` 不生效？**  
A: 确认 Redis 服务名称，在项目内点击 Redis 服务，Variables 中会显示实际变量名。引用格式为 `${{服务名.变量名}}`。

**Q: 连接被拒绝？**  
A: 确保使用 Railway 内部地址（`REDIS_HOST` 通常为 `xxx.railway.internal`），同一项目内服务通过内部网络通信。

**Q: REDIS_URL 格式？**  
A: 格式为 `redis://[:password@]host:port[/db]`，Railway 会自动生成，无需手动拼接。

---

## 相关文档

- [RAILWAY_MYSQL_INIT.md](./RAILWAY_MYSQL_INIT.md) - MySQL 初始化
- [RAILWAY_QUICK_START.md](./RAILWAY_QUICK_START.md) - Railway 快速开始
