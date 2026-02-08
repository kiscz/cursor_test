# 🔍 管理员登录问题排查总结

## 问题描述

管理后台登录一直返回 `{"error":"Invalid credentials"}` (401)

## 已完成的排查步骤

### ✅ 1. 网络和路由
- Nginx代理配置正确
- API请求能到达后端
- 后端端口9090正确监听

### ✅ 2. 数据库连接
- 配置已修改为使用容器名（shortdrama-mysql）
- 数据库连接正常
- short_drama数据库存在

### ✅ 3. 数据验证
- admin_users表存在
- 有2条admin记录
- email: admin@example.com
- password_hash已更新

### ✅ 4. 密码Hash
- 尝试了5个不同的bcrypt hash
- 所有都失败
- 说明问题不在hash格式

### ❌ 5. 查询问题（核心问题）
后端日志显示：
```
[rows:0] SELECT * FROM `admin_users` WHERE email = 'admin@example.com'
```

**查询返回0行，但数据库里明明有记录！**

## 可能的根本原因

1. **后端连接了错误的数据库实例**
   - 虽然config.yaml已改为shortdrama-mysql
   - 但可能有缓存或其他配置覆盖

2. **表名不匹配**
   - 后端查询 `admin_users`
   - 实际表名可能不同？

3. **字符编码/空格问题**
   - email字段可能有不可见字符

4. **GORM配置问题**
   - AutoMigrate可能创建了不同的表

## 建议的下一步

### 方案A：完全重建（推荐）⭐

```bash
# 1. 完全删除所有容器和volumes
docker-compose down -v

# 2. 重建所有服务
docker-compose up -d

# 3. 等待后端启动并创建表

# 4. 手动插入admin
docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama << 'EOF'
INSERT INTO admin_users (email, password_hash, name, role, is_active, created_at, updated_at)
VALUES ('admin@example.com', '$2a$10$CwTycUXWue0Thq9StjUM0uJ8Z8W5f2rBnhC1FtZrJ1FZ2H6P5Cx2S', 'Admin', 'admin', 1, NOW(), NOW());
EOF

# 5. 测试登录
```

### 方案B：调试后端数据库连接

运行验证脚本：
```bash
./verify-backend-connection.sh
```

### 方案C：临时绕过认证（开发环境）

修改 `backend/handlers/admin.go`，临时注释掉密码检查：

```go
// if !utils.CheckPassword(req.Password, admin.PasswordHash) {
//     c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
//     return
// }
```

重建后端并测试。

## 已创建的辅助脚本

```bash
./complete-diagnosis.sh         # 完整诊断
./try-known-hashes.sh          # 尝试多个hash
./verify-backend-connection.sh # 验证数据库连接
./rebuild-backend-final.sh     # 重建后端
./ultimate-fix.sh              # 终极修复
```

## 时间投入

已投入大量时间调试此问题。建议：
1. 先尝试完全重建（方案A）
2. 如果仍失败，考虑简化需求或换用其他认证方式

## 联系支持

如需进一步帮助，请提供：
1. `docker-compose logs backend` 完整输出
2. `docker exec shortdrama-mysql mysql -uroot -prootpassword short_drama -e "SELECT * FROM admin_users;"` 输出
3. `docker exec shortdrama-backend cat /root/config.yaml` 输出

---

**当前状态**: 🔴 登录功能未解决，建议完全重建系统
