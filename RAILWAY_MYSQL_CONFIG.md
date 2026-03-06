# Railway 使用 MySQL 配置指南

## ⚠️ 重要说明

**Railway 默认只提供 PostgreSQL 数据库服务**，不直接提供 MySQL。如果你需要使用 MySQL，有以下几种方案：

### 方案 1: 使用外部 MySQL 服务（推荐）

使用第三方 MySQL 服务（如 PlanetScale、Aiven、或自建 MySQL），然后在 Railway 中配置连接。

### 方案 2: 使用 Railway 的 MySQL 模板（如果可用）

Railway 可能提供 MySQL 模板，但需要检查当前可用性。

---

## 📝 环境变量配置（使用外部 MySQL）

如果使用外部 MySQL 服务（如 PlanetScale、Aiven、或自建），在 Railway 后端服务的 **Variables** 中配置：

### 必需的环境变量

```bash
# MySQL 数据库配置
DATABASE_HOST=your-mysql-host.com
DATABASE_PORT=3306
DATABASE_USER=your_mysql_user
DATABASE_PASSWORD=your_mysql_password
DATABASE_NAME=short_drama

# 不使用 PostgreSQL（重要！）
USE_POSTGRES=false

# 或者不设置 USE_POSTGRES，确保端口不是 5432
# DATABASE_PORT=3306  # MySQL 默认端口

# 服务器配置
SERVER_PORT=9090
SERVER_MODE=release

# JWT 配置
JWT_SECRET=your_production_jwt_secret_key_change_this
JWT_EXPIRES_HOURS=720

# CORS 配置
CORS_ALLOWED_ORIGINS=https://your-frontend.com
CORS_ALLOW_CREDENTIALS=true
```

### 完整环境变量列表

```bash
# ========== 数据库配置 ==========
DATABASE_HOST=your-mysql-host.com
DATABASE_PORT=3306
DATABASE_USER=your_mysql_user
DATABASE_PASSWORD=your_mysql_password
DATABASE_NAME=short_drama
USE_POSTGRES=false

# ========== 服务器配置 ==========
SERVER_PORT=9090
SERVER_MODE=release

# ========== Redis 配置（如果使用 Railway Redis）==========
REDIS_HOST=${{Redis.REDIS_HOST}}
REDIS_PORT=${{Redis.REDIS_PORT}}
REDIS_PASSWORD=${{Redis.REDIS_PASSWORD}}

# ========== JWT 配置 ==========
JWT_SECRET=your_production_jwt_secret_key_change_this_min_32_chars
JWT_EXPIRES_HOURS=720

# ========== CORS 配置 ==========
CORS_ALLOWED_ORIGINS=https://your-frontend.com,https://your-admin.com
CORS_ALLOW_CREDENTIALS=true

# ========== Stripe 配置（可选）==========
STRIPE_SECRET_KEY=sk_test_your_stripe_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
STRIPE_PRICE_MONTHLY=price_your_monthly_price_id
STRIPE_PRICE_YEARLY=price_your_yearly_price_id

# ========== AWS S3 配置（可选）==========
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_S3_BUCKET=your-bucket-name
```

---

## 🔧 环境变量支持

**已支持**：后端已支持通过环境变量覆盖配置（`DATABASE_*`、`MYSQL_*`、`USE_POSTGRES` 等）。详见 [RAILWAY_MYSQL_INIT.md](./RAILWAY_MYSQL_INIT.md) 获取完整初始化步骤。

### 解决方案 A: 修改代码支持环境变量（推荐）

需要修改 `backend/config/config.go` 和 `backend/main.go` 以支持环境变量覆盖。

### 解决方案 B: 使用配置文件挂载

在 Railway 中通过 Volume 挂载自定义 `config.yaml` 文件。

### 解决方案 C: 修改 Dockerfile 生成配置

修改 Dockerfile，在构建时根据环境变量生成 `config.yaml`。

---

## 🛠️ 方案 A: 修改代码支持环境变量

### 修改 `backend/config/config.go`

添加环境变量支持：

```go
package config

import (
	"os"
	"strconv"
	"strings"
	"gopkg.in/yaml.v3"
)

// ... 现有代码 ...

func Load(filename string) (*Config, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, err
	}

	// 环境变量覆盖（优先级高于 YAML）
	overrideFromEnv(&config)

	return &config, nil
}

func overrideFromEnv(cfg *Config) {
	// Server
	if port := os.Getenv("SERVER_PORT"); port != "" {
		if p, err := strconv.Atoi(port); err == nil {
			cfg.Server.Port = p
		}
	}
	if mode := os.Getenv("SERVER_MODE"); mode != "" {
		cfg.Server.Mode = mode
	}

	// Database
	if host := os.Getenv("DATABASE_HOST"); host != "" {
		cfg.Database.Host = host
	}
	if port := os.Getenv("DATABASE_PORT"); port != "" {
		if p, err := strconv.Atoi(port); err == nil {
			cfg.Database.Port = p
		}
	}
	if user := os.Getenv("DATABASE_USER"); user != "" {
		cfg.Database.User = user
	}
	if password := os.Getenv("DATABASE_PASSWORD"); password != "" {
		cfg.Database.Password = password
	}
	if dbname := os.Getenv("DATABASE_NAME"); dbname != "" {
		cfg.Database.DBName = dbname
	}

	// Redis
	if host := os.Getenv("REDIS_HOST"); host != "" {
		cfg.Redis.Host = host
	}
	if port := os.Getenv("REDIS_PORT"); port != "" {
		if p, err := strconv.Atoi(port); err == nil {
			cfg.Redis.Port = p
		}
	}
	if password := os.Getenv("REDIS_PASSWORD"); password != "" {
		cfg.Redis.Password = password
	}

	// JWT
	if secret := os.Getenv("JWT_SECRET"); secret != "" {
		cfg.JWT.Secret = secret
	}
	if hours := os.Getenv("JWT_EXPIRES_HOURS"); hours != "" {
		if h, err := strconv.Atoi(hours); err == nil {
			cfg.JWT.ExpiresHours = h
		}
	}

	// CORS
	if origins := os.Getenv("CORS_ALLOWED_ORIGINS"); origins != "" {
		cfg.CORS.AllowedOrigins = strings.Split(origins, ",")
	}
	if allowCreds := os.Getenv("CORS_ALLOW_CREDENTIALS"); allowCreds != "" {
		cfg.CORS.AllowCredentials = allowCreds == "true"
	}

	// Stripe
	if key := os.Getenv("STRIPE_SECRET_KEY"); key != "" {
		cfg.Stripe.SecretKey = key
	}
	if secret := os.Getenv("STRIPE_WEBHOOK_SECRET"); secret != "" {
		cfg.Stripe.WebhookSecret = secret
	}
	if monthly := os.Getenv("STRIPE_PRICE_MONTHLY"); monthly != "" {
		cfg.Stripe.PriceMonthly = monthly
	}
	if yearly := os.Getenv("STRIPE_PRICE_YEARLY"); yearly != "" {
		cfg.Stripe.PriceYearly = yearly
	}

	// AWS
	if region := os.Getenv("AWS_REGION"); region != "" {
		cfg.AWS.Region = region
	}
	if key := os.Getenv("AWS_ACCESS_KEY_ID"); key != "" {
		cfg.AWS.AccessKeyID = key
	}
	if secret := os.Getenv("AWS_SECRET_ACCESS_KEY"); secret != "" {
		cfg.AWS.SecretAccessKey = secret
	}
	if bucket := os.Getenv("AWS_S3_BUCKET"); bucket != "" {
		cfg.AWS.S3Bucket = bucket
	}
}
```

---

## 🛠️ 方案 B: 使用 Volume 挂载配置

### 在 Railway 中挂载配置文件

1. 在 Railway 项目页面，点击后端服务
2. 进入 **"Settings"** → **"Volumes"**
3. 创建 Volume
4. 挂载到 `/root/config.yaml`
5. 上传你的 `config.yaml` 文件到 Volume

### 配置文件示例 (`config.yaml`)

```yaml
server:
  port: 9090
  mode: release

database:
  host: your-mysql-host.com
  port: 3306
  user: your_mysql_user
  password: your_mysql_password
  dbname: short_drama
  max_idle_conns: 10
  max_open_conns: 100

redis:
  host: ${{Redis.REDIS_HOST}}  # Railway 变量引用可能不工作，需要实际值
  port: 6379
  password: ""
  db: 0

jwt:
  secret: your_production_jwt_secret_key_change_this
  expires_hours: 720

cors:
  allowed_origins:
    - https://your-frontend.com
    - https://your-admin.com
  allow_credentials: true
```

---

## 🛠️ 方案 C: 修改 Dockerfile 生成配置

### 修改根目录 `Dockerfile`

在构建阶段根据环境变量生成 `config.yaml`：

```dockerfile
# ... 现有代码 ...

# 生成配置文件
RUN cat > /root/config.yaml << EOF
server:
  port: \${SERVER_PORT:-9090}
  mode: \${SERVER_MODE:-release}

database:
  host: \${DATABASE_HOST:-mysql}
  port: \${DATABASE_PORT:-3306}
  user: \${DATABASE_USER:-root}
  password: \${DATABASE_PASSWORD:-rootpassword}
  dbname: \${DATABASE_NAME:-short_drama}
  max_idle_conns: 10
  max_open_conns: 100

redis:
  host: \${REDIS_HOST:-redis}
  port: \${REDIS_PORT:-6379}
  password: \${REDIS_PASSWORD:-}
  db: 0

jwt:
  secret: \${JWT_SECRET:-your_jwt_secret_key_change_this_in_production}
  expires_hours: \${JWT_EXPIRES_HOURS:-720}
EOF

# ... 现有代码 ...
```

**注意**：这种方法在构建时生成配置，环境变量需要在构建时可用。

---

## 📊 推荐方案对比

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| **方案 A**（代码支持环境变量） | 灵活，符合 12-Factor App | 需要修改代码 | ⭐⭐⭐⭐⭐ |
| **方案 B**（Volume 挂载） | 不需要改代码 | 配置管理复杂，需要手动上传文件 | ⭐⭐⭐ |
| **方案 C**（Dockerfile 生成） | 自动化 | 构建时环境变量限制 | ⭐⭐⭐ |

---

## 🎯 快速配置步骤（使用方案 A）

1. **修改代码支持环境变量**（见上方代码）

2. **在 Railway Variables 中配置**：
   ```bash
   DATABASE_HOST=your-mysql-host.com
   DATABASE_PORT=3306
   DATABASE_USER=your_user
   DATABASE_PASSWORD=your_password
   DATABASE_NAME=short_drama
   USE_POSTGRES=false
   SERVER_PORT=9090
   SERVER_MODE=release
   JWT_SECRET=your_secret_key
   ```

3. **重新部署服务**

---

## 🔗 推荐的 MySQL 服务提供商

### PlanetScale（推荐）
- **免费额度**：5GB 数据库
- **特点**：无服务器 MySQL，自动扩展
- **网址**：https://planetscale.com

### Aiven
- **免费额度**：$300 免费额度（30 天）
- **特点**：托管 MySQL，支持多种云平台
- **网址**：https://aiven.io

### 自建 MySQL（VPS）
- **成本**：$2-5/月（Vultr、DigitalOcean）
- **特点**：完全控制
- **需要**：技术能力

---

## ✅ 检查清单

- [ ] MySQL 服务已创建并运行
- [ ] 获取 MySQL 连接信息（主机、端口、用户名、密码）
- [ ] 在 Railway Variables 中配置数据库连接
- [ ] 设置 `USE_POSTGRES=false` 或确保端口是 3306
- [ ] 运行数据库迁移（使用 MySQL schema）
- [ ] 测试数据库连接
- [ ] 查看日志确认连接成功

---

## 🐛 常见问题

**Q: Railway 是否提供 MySQL？**
A: Railway 默认只提供 PostgreSQL。如果需要 MySQL，使用外部服务（如 PlanetScale）或自建。

**Q: 如何确认使用的是 MySQL 而不是 PostgreSQL？**
A: 检查 `USE_POSTGRES` 环境变量为 `false`，或确保 `DATABASE_PORT=3306`（MySQL 默认端口）。

**Q: 环境变量不生效？**
A: 当前代码可能不支持环境变量覆盖，需要修改代码（方案 A）或使用其他方案。

**Q: 如何运行 MySQL 迁移？**
A: 使用 `database/schema.sql`（MySQL 格式），通过 MySQL 客户端或 Railway CLI 执行。

---

**需要我帮你实现方案 A（代码支持环境变量）吗？**
