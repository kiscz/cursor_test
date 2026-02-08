package handlers

import (
	"net/http"
	"shortdrama/database"
	"shortdrama/models"
	"strconv"

	"github.com/gin-gonic/gin"
)

func GetFavorites(c *gin.Context) {
	userID := c.GetUint("userID")

	var favorites []models.UserFavorite
	if err := database.DB.Where("user_id = ?", userID).
		Preload("Drama").
		Preload("Drama.Category").
		Order("created_at DESC").
		Find(&favorites).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch favorites"})
		return
	}

	c.JSON(http.StatusOK, favorites)
}

func CheckFavorite(c *gin.Context) {
	userID := c.GetUint("userID")
	dramaID := c.Param("dramaId")

	var count int64
	database.DB.Model(&models.UserFavorite{}).
		Where("user_id = ? AND drama_id = ?", userID, dramaID).
		Count(&count)

	c.JSON(http.StatusOK, gin.H{
		"is_favorite": count > 0,
	})
}

func AddFavorite(c *gin.Context) {
	userID := c.GetUint("userID")
	dramaID := c.Param("dramaId")

	// Check if already exists
	var existing models.UserFavorite
	if err := database.DB.Where("user_id = ? AND drama_id = ?", userID, dramaID).
		First(&existing).Error; err == nil {
		c.JSON(http.StatusOK, gin.H{"message": "Already in favorites"})
		return
	}

	dramaIDInt, _ := strconv.Atoi(dramaID)
	favorite := models.UserFavorite{
		UserID:  userID,
		DramaID: uint(dramaIDInt),
	}

	if err := database.DB.Create(&favorite).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add favorite"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Added to favorites"})
}

func RemoveFavorite(c *gin.Context) {
	userID := c.GetUint("userID")
	dramaID := c.Param("dramaId")

	if err := database.DB.Where("user_id = ? AND drama_id = ?", userID, dramaID).
		Delete(&models.UserFavorite{}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove favorite"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Removed from favorites"})
}

// Helper function moved to handlers.go
