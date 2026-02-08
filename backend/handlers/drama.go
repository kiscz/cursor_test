package handlers

import (
	"net/http"
	"shortdrama/database"
	"shortdrama/models"
	"strconv"

	"github.com/gin-gonic/gin"
)

func GetDramas(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	categoryID := c.Query("category_id")
	search := c.Query("q")

	offset := (page - 1) * limit

	query := database.DB.Model(&models.Drama{}).Where("status = ?", "published")

	if categoryID != "" {
		query = query.Where("category_id = ?", categoryID)
	}

	if search != "" {
		query = query.Where("title_en LIKE ? OR title_es LIKE ? OR title_pt LIKE ?",
			"%"+search+"%", "%"+search+"%", "%"+search+"%")
	}

	var dramas []models.Drama
	if err := query.Preload("Category").
		Order("views DESC").
		Offset(offset).
		Limit(limit).
		Find(&dramas).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch dramas"})
		return
	}

	c.JSON(http.StatusOK, dramas)
}

func GetFeaturedDramas(c *gin.Context) {
	var dramas []models.Drama
	if err := database.DB.Where("status = ? AND is_featured = ?", "published", true).
		Preload("Category").
		Order("views DESC").
		Limit(5).
		Find(&dramas).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch featured dramas"})
		return
	}

	c.JSON(http.StatusOK, dramas)
}

func GetTrendingDramas(c *gin.Context) {
	var dramas []models.Drama
	if err := database.DB.Where("status = ?", "published").
		Preload("Category").
		Order("views DESC").
		Limit(20).
		Find(&dramas).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch trending dramas"})
		return
	}

	c.JSON(http.StatusOK, dramas)
}

func GetNewDramas(c *gin.Context) {
	var dramas []models.Drama
	if err := database.DB.Where("status = ?", "published").
		Preload("Category").
		Order("published_at DESC").
		Limit(20).
		Find(&dramas).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch new dramas"})
		return
	}

	c.JSON(http.StatusOK, dramas)
}

func GetDrama(c *gin.Context) {
	id := c.Param("id")

	var drama models.Drama
	if err := database.DB.Preload("Category").First(&drama, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Drama not found"})
		return
	}

	// Count published episodes
	var publishedEpisodesCount int64
	database.DB.Model(&models.Episode{}).Where("drama_id = ?", drama.ID).Count(&publishedEpisodesCount)

	// Increment views
	database.DB.Model(&drama).Update("views", drama.Views+1)

	// Create response with published episodes count
	response := gin.H{
		"id":                   drama.ID,
		"title_en":             drama.TitleEN,
		"title_es":             drama.TitleES,
		"title_pt":             drama.TitlePT,
		"description_en":       drama.DescriptionEN,
		"description_es":       drama.DescriptionES,
		"description_pt":       drama.DescriptionPT,
		"poster_url":           drama.PosterURL,
		"banner_url":           drama.BannerURL,
		"trailer_url":          drama.TrailerURL,
		"category_id":          drama.CategoryID,
		"category":             drama.Category,
		"total_episodes":       drama.TotalEpisodes,
		"published_episodes":   int(publishedEpisodesCount), // 已上架集数
		"free_episodes":       drama.FreeEpisodes,
		"duration_per_episode": drama.DurationPerEpisode,
		"rating":               drama.Rating,
		"views":                drama.Views,
		"is_featured":          drama.IsFeatured,
		"is_premium_only":      drama.IsPremiumOnly,
		"status":               drama.Status,
		"published_at":         drama.PublishedAt,
		"created_at":           drama.CreatedAt,
		"updated_at":           drama.UpdatedAt,
	}

	c.JSON(http.StatusOK, response)
}

func GetDramaEpisodes(c *gin.Context) {
	dramaID := c.Param("id")

	var episodes []models.Episode
	if err := database.DB.Where("drama_id = ?", dramaID).
		Order("episode_number ASC").
		Find(&episodes).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch episodes"})
		return
	}

	c.JSON(http.StatusOK, episodes)
}

func GetEpisode(c *gin.Context) {
	id := c.Param("id")

	var episode models.Episode
	if err := database.DB.First(&episode, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Episode not found"})
		return
	}

	// Increment views
	database.DB.Model(&episode).Update("views", episode.Views+1)

	c.JSON(http.StatusOK, episode)
}

func GetCategories(c *gin.Context) {
	var categories []models.Category
	if err := database.DB.Where("is_active = ?", true).
		Order("sort_order ASC").
		Find(&categories).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch categories"})
		return
	}

	c.JSON(http.StatusOK, categories)
}
