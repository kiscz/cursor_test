package database

import (
	"context"
	"fmt"
	"os"
	"shortdrama/config"
	"shortdrama/models"
	"time"

	"github.com/go-redis/redis/v8"
	"gorm.io/driver/mysql"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var (
	DB  *gorm.DB
	RDB *redis.Client
	ctx = context.Background()
)

func Init(cfg *config.Config) error {
	// Check if using PostgreSQL (Supabase) or MySQL
	usePostgres := os.Getenv("USE_POSTGRES") == "true" || cfg.Database.Port == 5432
	
	var db *gorm.DB
	var err error

	if usePostgres {
		// Initialize PostgreSQL (for Supabase)
		dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%d sslmode=require TimeZone=UTC",
			cfg.Database.Host,
			cfg.Database.User,
			cfg.Database.Password,
			cfg.Database.DBName,
			cfg.Database.Port,
		)
		db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
		if err != nil {
			return fmt.Errorf("failed to connect to PostgreSQL database: %w", err)
		}
	} else {
		// Initialize MySQL
		dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4&parseTime=True&loc=Local",
			cfg.Database.User,
			cfg.Database.Password,
			cfg.Database.Host,
			cfg.Database.Port,
			cfg.Database.DBName,
		)
		db, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
		if err != nil {
			return fmt.Errorf("failed to connect to MySQL database: %w", err)
		}
	}

	sqlDB, err := db.DB()
	if err != nil {
		return fmt.Errorf("failed to get database instance: %w", err)
	}

	sqlDB.SetMaxIdleConns(cfg.Database.MaxIdleConns)
	sqlDB.SetMaxOpenConns(cfg.Database.MaxOpenConns)
	sqlDB.SetConnMaxLifetime(time.Hour)

	DB = db

	// MySQL specific: Disable foreign key checks temporarily
	if !usePostgres {
		DB.Exec("SET FOREIGN_KEY_CHECKS=0")
	}

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
		if !usePostgres {
			// Re-enable foreign key checks before returning error
			DB.Exec("SET FOREIGN_KEY_CHECKS=1")
		}
		return fmt.Errorf("failed to auto migrate: %w", err)
	}

	// MySQL specific: Re-enable foreign key checks
	if !usePostgres {
		DB.Exec("SET FOREIGN_KEY_CHECKS=1")
	}

	// Initialize Redis
	RDB = redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%d", cfg.Redis.Host, cfg.Redis.Port),
		Password: cfg.Redis.Password,
		DB:       cfg.Redis.DB,
	})

	if err := RDB.Ping(ctx).Err(); err != nil {
		return fmt.Errorf("failed to connect to redis: %w", err)
	}

	return nil
}

func GetDB() *gorm.DB {
	return DB
}

func GetRedis() *redis.Client {
	return RDB
}
