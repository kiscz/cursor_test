// +build postgres

package database

import (
	"fmt"
	"shortdrama/config"
	"shortdrama/models"
	"time"

	"github.com/go-redis/redis/v8"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func Init(cfg *config.Config) error {
	// Initialize PostgreSQL
	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%d sslmode=require TimeZone=UTC",
		cfg.Database.Host,
		cfg.Database.User,
		cfg.Database.Password,
		cfg.Database.DBName,
		cfg.Database.Port,
	)

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return fmt.Errorf("failed to connect to database: %w", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		return fmt.Errorf("failed to get database instance: %w", err)
	}

	sqlDB.SetMaxIdleConns(cfg.Database.MaxIdleConns)
	sqlDB.SetMaxOpenConns(cfg.Database.MaxOpenConns)
	sqlDB.SetConnMaxLifetime(time.Hour)

	DB = db

	// Auto migrate models
	if err := DB.AutoMigrate(
		&models.User{},
		&models.Category{},
		&models.Drama{},
		&models.Episode{},
		&models.UserFavorite{},
		&models.WatchHistory{},
		&models.AdReward{},
		&models.Subscription{},
		&models.AdminUser{},
	); err != nil {
		return fmt.Errorf("failed to auto migrate: %w", err)
	}

	// Initialize Redis (use Upstash or external Redis)
	RDB = redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%d", cfg.Redis.Host, cfg.Redis.Port),
		Password: cfg.Redis.Password,
		DB:       cfg.Redis.DB,
	})

	if err := RDB.Ping(ctx).Err(); err != nil {
		// Redis is optional, log warning but don't fail
		fmt.Printf("Warning: Redis connection failed: %v\n", err)
		RDB = nil
	}

	return nil
}
