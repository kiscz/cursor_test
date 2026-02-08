package handlers

import (
	"net/http"
	"shortdrama/database"
	"shortdrama/models"
	"time"

	"github.com/gin-gonic/gin"
)

func GetWatchHistory(c *gin.Context) {
	userID := c.GetUint("userID")

	var history []models.WatchHistory
	if err := database.DB.Where("user_id = ?", userID).
		Preload("Drama").
		Preload("Drama.Category").
		Preload("Episode").
		Order("last_watched_at DESC").
		Limit(50).
		Find(&history).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch history"})
		return
	}

	c.JSON(http.StatusOK, history)
}

func GetContinueWatching(c *gin.Context) {
	userID := c.GetUint("userID")

	var history []models.WatchHistory
	if err := database.DB.Where("user_id = ? AND completed = ?", userID, false).
		Preload("Drama").
		Preload("Drama.Category").
		Preload("Episode").
		Order("last_watched_at DESC").
		Limit(10).
		Find(&history).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch continue watching"})
		return
	}

	// Calculate progress percentage
	type ContinueWatchItem struct {
		models.WatchHistory
		Progress float64 `json:"progress"`
	}

	result := make([]ContinueWatchItem, len(history))
	for i, h := range history {
		progressPercent := float64(h.Progress) / float64(h.Episode.Duration) * 100
		result[i] = ContinueWatchItem{
			WatchHistory: h,
			Progress:     progressPercent,
		}
	}

	c.JSON(http.StatusOK, result)
}

func GetEpisodeProgress(c *gin.Context) {
	userID := c.GetUint("userID")
	episodeID := c.Param("episodeId")

	var history models.WatchHistory
	if err := database.DB.Where("user_id = ? AND episode_id = ?", userID, episodeID).
		First(&history).Error; err != nil {
		c.JSON(http.StatusOK, gin.H{"progress": 0, "completed": false})
		return
	}

	c.JSON(http.StatusOK, history)
}

func SaveWatchProgress(c *gin.Context) {
	userID := c.GetUint("userID")

	var req struct {
		DramaID   uint `json:"drama_id" binding:"required"`
		EpisodeID uint `json:"episode_id" binding:"required"`
		Progress  int  `json:"progress" binding:"required"`
		Completed bool `json:"completed"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Check if history exists
	var history models.WatchHistory
	result := database.DB.Where("user_id = ? AND episode_id = ?", userID, req.EpisodeID).
		First(&history)

	if result.Error != nil {
		// Create new history
		history = models.WatchHistory{
			UserID:        userID,
			DramaID:       req.DramaID,
			EpisodeID:     req.EpisodeID,
			Progress:      req.Progress,
			Completed:     req.Completed,
			LastWatchedAt: time.Now(),
		}
		database.DB.Create(&history)
	} else {
		// Update existing history
		database.DB.Model(&history).Updates(map[string]interface{}{
			"progress":        req.Progress,
			"completed":       req.Completed,
			"last_watched_at": time.Now(),
		})
	}

	c.JSON(http.StatusOK, history)
}
