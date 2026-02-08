package handlers

import (
	"log"
	"net/http"
	"shortdrama/database"
	"shortdrama/models"
	"shortdrama/utils"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// Temporary endpoint to generate bcrypt hash
func GenerateHash(c *gin.Context) {
	var req struct {
		Password string `json:"password"`
	}
	
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	
	hash, err := utils.HashPassword(req.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	log.Printf("[HASH-GEN] Generated hash for password '%s': %s", req.Password, hash)
	
	c.JSON(http.StatusOK, gin.H{
		"password": req.Password,
		"hash": hash,
		"length": len(hash),
	})
}

// AdminRegister 创建或重置管理员账号（用于首次部署/重置密码，无鉴权）
func AdminRegister(c *gin.Context) {
	var req struct {
		Email    string `json:"email" binding:"required,email"`
		Password string `json:"password" binding:"required,min=6"`
		Name     string `json:"name"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	hash, err := utils.HashPassword(req.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}
	name := req.Name
	if name == "" {
		name = "Admin"
	}
	var admin models.AdminUser
	err = database.DB.Where("email = ?", req.Email).First(&admin).Error
	if err == nil {
		// 已存在则更新密码
		database.DB.Model(&admin).Updates(map[string]interface{}{
			"password_hash": hash,
			"name":          name,
			"is_active":     true,
		})
		c.JSON(http.StatusOK, gin.H{"message": "Admin password updated", "email": req.Email})
		return
	}
	admin = models.AdminUser{
		Email:        req.Email,
		PasswordHash: hash,
		Name:         name,
		Role:         "admin",
		IsActive:     true,
	}
	if err := database.DB.Create(&admin).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create admin"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"message": "Admin created", "email": req.Email})
}

func AdminLogin(c *gin.Context) {
	var req struct {
		Email    string `json:"email" binding:"required"`
		Password string `json:"password" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	log.Printf("[DEBUG] Login attempt - Email: %s, Password length: %d", req.Email, len(req.Password))

	var admin models.AdminUser
	if err := database.DB.Where("email = ?", req.Email).First(&admin).Error; err != nil {
		log.Printf("[DEBUG] User not found: %v", err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}

	log.Printf("[DEBUG] User found - ID: %d, Hash length: %d, Hash: %s", admin.ID, len(admin.PasswordHash), admin.PasswordHash[:30]+"...")

	checkResult := utils.CheckPassword(req.Password, admin.PasswordHash)
	log.Printf("[DEBUG] CheckPassword result: %v", checkResult)
	
	if !checkResult {
		log.Printf("[DEBUG] Password check failed for user: %s", req.Email)
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
		return
	}
	
	log.Printf("[DEBUG] Login successful for user: %s", req.Email)

	if !admin.IsActive {
		c.JSON(http.StatusForbidden, gin.H{"error": "Account is deactivated"})
		return
	}

	// Update last login
	now := time.Now()
	database.DB.Model(&admin).Update("last_login_at", &now)

	// Generate token
	token, err := utils.GenerateAdminToken(admin.ID, admin.Role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token": token,
		"admin": admin,
	})
}

func AdminGetDramas(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	status := c.Query("status")      // 可选的status过滤
	categoryID := c.Query("category_id")
	search := c.Query("q")

	offset := (page - 1) * limit

	// 管理员可以看到所有状态的drama
	query := database.DB.Model(&models.Drama{})

	// 如果指定了status，则过滤
	if status != "" {
		query = query.Where("status = ?", status)
	}

	if categoryID != "" {
		query = query.Where("category_id = ?", categoryID)
	}

	if search != "" {
		query = query.Where("title LIKE ? OR description LIKE ?",
			"%"+search+"%", "%"+search+"%")
	}

	var total int64
	query.Count(&total)

	var dramas []models.Drama
	if err := query.Preload("Category").
		Order("created_at DESC").
		Offset(offset).
		Limit(limit).
		Find(&dramas).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch dramas"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":  dramas,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

func AdminCreateDrama(c *gin.Context) {
	var drama models.Drama
	if err := c.ShouldBindJSON(&drama); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := database.DB.Create(&drama).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create drama"})
		return
	}

	c.JSON(http.StatusCreated, drama)
}

func AdminUpdateDrama(c *gin.Context) {
	id := c.Param("id")

	var drama models.Drama
	if err := database.DB.First(&drama, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Drama not found"})
		return
	}

	var updates models.Drama
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := database.DB.Model(&drama).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update drama"})
		return
	}

	c.JSON(http.StatusOK, drama)
}

func AdminDeleteDrama(c *gin.Context) {
	id := c.Param("id")

	if err := database.DB.Delete(&models.Drama{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete drama"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Drama deleted"})
}

func AdminCreateEpisode(c *gin.Context) {
	var episode models.Episode
	if err := c.ShouldBindJSON(&episode); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := database.DB.Create(&episode).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create episode"})
		return
	}

	c.JSON(http.StatusCreated, episode)
}

func AdminUpdateEpisode(c *gin.Context) {
	id := c.Param("id")

	var episode models.Episode
	if err := database.DB.First(&episode, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Episode not found"})
		return
	}

	var updates models.Episode
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := database.DB.Model(&episode).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update episode"})
		return
	}

	c.JSON(http.StatusOK, episode)
}

func AdminDeleteEpisode(c *gin.Context) {
	id := c.Param("id")

	if err := database.DB.Delete(&models.Episode{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete episode"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Episode deleted"})
}

func AdminCreateCategory(c *gin.Context) {
	var category models.Category
	if err := c.ShouldBindJSON(&category); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := database.DB.Create(&category).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create category"})
		return
	}

	c.JSON(http.StatusCreated, category)
}

func AdminUpdateCategory(c *gin.Context) {
	id := c.Param("id")

	var category models.Category
	if err := database.DB.First(&category, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Category not found"})
		return
	}

	var updates models.Category
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := database.DB.Model(&category).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update category"})
		return
	}

	c.JSON(http.StatusOK, category)
}

func AdminDeleteCategory(c *gin.Context) {
	id := c.Param("id")

	if err := database.DB.Delete(&models.Category{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete category"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Category deleted"})
}

func AdminGetUsers(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset := (page - 1) * limit

	var users []models.User
	var total int64

	database.DB.Model(&models.User{}).Count(&total)
	database.DB.Order("created_at DESC").Offset(offset).Limit(limit).Find(&users)

	c.JSON(http.StatusOK, gin.H{
		"users": users,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}

func AdminGetUser(c *gin.Context) {
	id := c.Param("id")

	var user models.User
	if err := database.DB.First(&user, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, user)
}

func AdminGetStats(c *gin.Context) {
	var stats struct {
		TotalUsers        int64 `json:"total_users"`
		PremiumUsers      int64 `json:"premium_users"`
		TotalDramas       int64 `json:"total_dramas"`
		TotalEpisodes     int64 `json:"total_episodes"`
		TotalViews        int64 `json:"total_views"`
		ActiveSubscriptions int64 `json:"active_subscriptions"`
	}

	database.DB.Model(&models.User{}).Count(&stats.TotalUsers)
	database.DB.Model(&models.User{}).Where("is_premium = ?", true).Count(&stats.PremiumUsers)
	database.DB.Model(&models.Drama{}).Where("status = ?", "published").Count(&stats.TotalDramas)
	database.DB.Model(&models.Episode{}).Count(&stats.TotalEpisodes)
	database.DB.Model(&models.Drama{}).Select("SUM(views)").Scan(&stats.TotalViews)
	database.DB.Model(&models.Subscription{}).Where("status = ?", "active").Count(&stats.ActiveSubscriptions)

	c.JSON(http.StatusOK, stats)
}
