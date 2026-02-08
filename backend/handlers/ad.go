package handlers

import (
	"net/http"
	"shortdrama/database"
	"shortdrama/models"

	"github.com/gin-gonic/gin"
)

// CheckAdUnlock checks if user has unlocked an episode by watching ads
func CheckAdUnlock(c *gin.Context) {
	userID := c.GetUint("userID")
	episodeID := c.Param("episodeId")

	var count int64
	database.DB.Model(&models.AdReward{}).
		Where("user_id = ? AND episode_id = ?", userID, episodeID).
		Count(&count)

	c.JSON(http.StatusOK, gin.H{
		"unlocked": count > 0,
	})
}

func RecordAdReward(c *gin.Context) {
	userID := c.GetUint("userID")

	var req struct {
		EpisodeID  uint   `json:"episode_id" binding:"required"`
		AdNetwork  string `json:"ad_network"`
		RewardType string `json:"reward_type"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if already unlocked
	var existingReward models.AdReward
	if err := database.DB.Where("user_id = ? AND episode_id = ?", userID, req.EpisodeID).
		First(&existingReward).Error; err == nil {
		// Already unlocked
		c.JSON(http.StatusOK, gin.H{
			"message": "Episode already unlocked",
			"unlocked": true,
		})
		return
	}

	adReward := models.AdReward{
		UserID:     userID,
		EpisodeID:  req.EpisodeID,
		AdNetwork:  req.AdNetwork,
		RewardType: req.RewardType,
		IPAddress:  c.ClientIP(),
		UserAgent:  c.GetHeader("User-Agent"),
	}

	if err := database.DB.Create(&adReward).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to record ad reward"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Ad reward recorded",
		"unlocked": true,
	})
}
