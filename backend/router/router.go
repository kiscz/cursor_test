package router

import (
	"shortdrama/config"
	"shortdrama/handlers"
	"shortdrama/middlewares"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func Setup(cfg *config.Config) *gin.Engine {
	r := gin.Default()

	// CORS
	corsConfig := cors.DefaultConfig()
	corsConfig.AllowOrigins = cfg.CORS.AllowedOrigins
	corsConfig.AllowCredentials = cfg.CORS.AllowCredentials
	corsConfig.AllowHeaders = []string{"Origin", "Content-Type", "Authorization"}
	r.Use(cors.New(corsConfig))

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// API routes
	api := r.Group("/api")
	{
		// Auth routes
		auth := api.Group("/auth")
		{
			auth.POST("/register", handlers.Register)
			auth.POST("/login", handlers.Login)
			auth.GET("/me", middlewares.AuthRequired(), handlers.GetMe)
		}

		// Drama routes
		dramas := api.Group("/dramas")
		{
			dramas.GET("", handlers.GetDramas)
			dramas.GET("/featured", handlers.GetFeaturedDramas)
			dramas.GET("/trending", handlers.GetTrendingDramas)
			dramas.GET("/new", handlers.GetNewDramas)
			dramas.GET("/:id", handlers.GetDrama)
			dramas.GET("/:id/episodes", handlers.GetDramaEpisodes)
		}

		// Episode routes
		episodes := api.Group("/episodes")
		{
			episodes.GET("/:id", handlers.GetEpisode)
		}

		// Category routes
		categories := api.Group("/categories")
		{
			categories.GET("", handlers.GetCategories)
		}

		// Favorites routes (requires auth)
		favorites := api.Group("/favorites")
		favorites.Use(middlewares.AuthRequired())
		{
			favorites.GET("", handlers.GetFavorites)
			favorites.GET("/check/:dramaId", handlers.CheckFavorite)
			favorites.POST("/:dramaId", handlers.AddFavorite)
			favorites.DELETE("/:dramaId", handlers.RemoveFavorite)
		}

		// Watch history routes (requires auth)
		history := api.Group("/watch-history")
		history.Use(middlewares.AuthRequired())
		{
			history.GET("", handlers.GetWatchHistory)
			history.GET("/continue", handlers.GetContinueWatching)
			history.GET("/:episodeId", handlers.GetEpisodeProgress)
			history.POST("", handlers.SaveWatchProgress)
		}

		// Ad reward routes (requires auth)
		ads := api.Group("/ads")
		ads.Use(middlewares.AuthRequired())
		{
			ads.GET("/check/:episodeId", handlers.CheckAdUnlock)
			ads.POST("/reward", handlers.RecordAdReward)
		}

		// Subscription routes (requires auth)
		subscriptions := api.Group("/subscriptions")
		subscriptions.Use(middlewares.AuthRequired())
		{
			subscriptions.POST("/create-checkout", handlers.CreateCheckoutSession)
			subscriptions.GET("/status", handlers.GetSubscriptionStatus)
			subscriptions.POST("/cancel", handlers.CancelSubscription)
		}

		// Stripe webhook (no auth required)
		api.POST("/webhooks/stripe", handlers.HandleStripeWebhook)

		// User routes (requires auth)
		users := api.Group("/users")
		users.Use(middlewares.AuthRequired())
		{
			users.PUT("/profile", handlers.UpdateProfile)
		}

		// Admin routes
		admin := api.Group("/admin")
		admin.Use(middlewares.AdminAuthRequired())
		{
			// Drama management
			admin.GET("/dramas", handlers.AdminGetDramas)        // 获取所有状态的drama
			admin.POST("/dramas", handlers.AdminCreateDrama)
			admin.PUT("/dramas/:id", handlers.AdminUpdateDrama)
			admin.DELETE("/dramas/:id", handlers.AdminDeleteDrama)

			// Episode management
			admin.POST("/episodes", handlers.AdminCreateEpisode)
			admin.PUT("/episodes/:id", handlers.AdminUpdateEpisode)
			admin.DELETE("/episodes/:id", handlers.AdminDeleteEpisode)

			// Category management
			admin.POST("/categories", handlers.AdminCreateCategory)
			admin.PUT("/categories/:id", handlers.AdminUpdateCategory)
			admin.DELETE("/categories/:id", handlers.AdminDeleteCategory)

			// User management
			admin.GET("/users", handlers.AdminGetUsers)
			admin.GET("/users/:id", handlers.AdminGetUser)

			// Statistics
			admin.GET("/stats", handlers.AdminGetStats)
		}

		// Admin auth
		adminAuth := api.Group("/admin/auth")
		{
			adminAuth.POST("/register", handlers.AdminRegister) // 创建/重置管理员（无鉴权，仅部署用）
			adminAuth.POST("/login", handlers.AdminLogin)
			adminAuth.POST("/generate-hash", handlers.GenerateHash) // Temporary for debugging
		}
	}

	return r
}
