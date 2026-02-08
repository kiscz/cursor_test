# Supabase 配置

## 文件说明

- `migrations/20240209000000_initial_schema.sql` - 数据库迁移脚本（PostgreSQL）
- `config.toml` - Supabase 本地开发配置（可选）

## 使用方法

### 1. 在 Supabase Dashboard 运行迁移

1. 登录 Supabase Dashboard
2. 进入 **SQL Editor**
3. 复制 `migrations/20240209000000_initial_schema.sql` 的内容
4. 粘贴并执行

### 2. 使用 Supabase CLI（可选）

```bash
# 安装 Supabase CLI
npm install -g supabase

# 登录
supabase login

# 初始化项目（如果还没有）
supabase init

# 链接到远程项目
supabase link --project-ref your-project-ref

# 推送迁移
supabase db push
```

## 数据库差异说明

### MySQL → PostgreSQL 转换

1. **数据类型**:
   - `BIGINT UNSIGNED` → `BIGSERIAL` / `BIGINT`
   - `AUTO_INCREMENT` → `SERIAL` / `BIGSERIAL`
   - `ENUM` → `VARCHAR` + `CHECK` 约束
   - `TIMESTAMP` → `TIMESTAMP` (相同)

2. **索引**:
   - MySQL: `INDEX idx_name (column)`
   - PostgreSQL: `CREATE INDEX idx_name ON table(column)`

3. **外键**:
   - MySQL: `FOREIGN KEY (col) REFERENCES table(id)`
   - PostgreSQL: `CONSTRAINT fk_name FOREIGN KEY (col) REFERENCES table(id)`

4. **触发器**:
   - PostgreSQL 使用函数和触发器实现 `ON UPDATE CURRENT_TIMESTAMP`

## 注意事项

- Supabase 使用 PostgreSQL 15
- 默认启用 Row Level Security (RLS)，可能需要配置策略
- 连接必须使用 SSL (`sslmode=require`)
- 不支持 MySQL 的 `SET FOREIGN_KEY_CHECKS`
