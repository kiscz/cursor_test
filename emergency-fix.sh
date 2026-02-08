#!/bin/bash

echo "🚨 紧急修复方案"
echo "=========================="
echo ""

echo "方案：修改后端去掉密码验证（临时调试用）"
echo ""

read -p "是否继续？这会临时禁用密码验证 (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo ""
echo "1️⃣ 创建调试版本的admin.go..."

cat > /tmp/admin_debug.go << 'EOF'
// 临时调试：跳过密码验证
func AdminLogin(c *gin.Context) {
	var req struct {
		Email    string `json:"email" binding:"required"`
		Password string `json:"password" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var admin models.AdminUser
	if err := database.DB.Where("email = ?", req.Email).First(&admin).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	// 临时：跳过密码验证
	// if !utils.CheckPassword(req.Password, admin.PasswordHash) {
	// 	c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
	// 	return
	// }

	if !admin.IsActive {
		c.JSON(http.StatusForbidden, gin.H{"error": "Account is deactivated"})
		return
	}

	// 生成token...
	token, err := utils.GenerateAdminToken(admin.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	// Update last login
	now := time.Now()
	database.DB.Model(&admin).Update("last_login_at", &now)

	c.JSON(http.StatusOK, gin.H{
		"token": token,
		"admin": admin,
	})
}
EOF

echo "❌ 这个方案太危险，不建议使用"
echo ""
echo "让我们用正确的方法..."

rm /tmp/admin_debug.go
