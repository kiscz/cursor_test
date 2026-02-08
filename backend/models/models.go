package models

import (
	"time"
)

type User struct {
	ID               uint      `gorm:"primaryKey" json:"id"`
	Email            string    `gorm:"unique;not null" json:"email"`
	PasswordHash     string    `gorm:"not null" json:"-"`
	Username         string    `json:"username"`
	AvatarURL        string    `json:"avatar_url"`
	Language         string    `gorm:"default:en" json:"language"`
	IsPremium        bool      `gorm:"default:false" json:"is_premium"`
	PremiumExpiresAt *time.Time `json:"premium_expires_at"`
	StripeCustomerID string    `json:"stripe_customer_id"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

type Category struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	NameEN    string    `gorm:"not null" json:"name_en"`
	NameES    string    `json:"name_es"`
	NamePT    string    `json:"name_pt"`
	Slug      string    `gorm:"unique;not null" json:"slug"`
	Icon      string    `json:"icon"`
	SortOrder int       `gorm:"default:0" json:"sort_order"`
	IsActive  bool      `gorm:"default:true" json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
}

type Drama struct {
	ID                 uint      `gorm:"primaryKey" json:"id"`
	TitleEN            string    `gorm:"not null" json:"title_en"`
	TitleES            string    `json:"title_es"`
	TitlePT            string    `json:"title_pt"`
	DescriptionEN      string    `gorm:"type:text" json:"description_en"`
	DescriptionES      string    `gorm:"type:text" json:"description_es"`
	DescriptionPT      string    `gorm:"type:text" json:"description_pt"`
	PosterURL          string    `json:"poster_url"`
	BannerURL          string    `json:"banner_url"`
	TrailerURL         string    `json:"trailer_url"`
	CategoryID         *uint     `json:"category_id"`
	Category           *Category `gorm:"foreignKey:CategoryID" json:"category,omitempty"`
	TotalEpisodes      int       `gorm:"default:0" json:"total_episodes"`
	FreeEpisodes       int       `gorm:"default:3" json:"free_episodes"`
	DurationPerEpisode int       `gorm:"default:120" json:"duration_per_episode"`
	Rating             float64   `gorm:"type:decimal(3,2);default:0.00" json:"rating"`
	Views              int64     `gorm:"default:0" json:"views"`
	IsFeatured         bool      `gorm:"default:false" json:"is_featured"`
	IsPremiumOnly      bool      `gorm:"default:false" json:"is_premium_only"`
	Status             string    `gorm:"default:draft" json:"status"` // draft, published, archived
	PublishedAt        *time.Time `json:"published_at"`
	CreatedAt          time.Time `json:"created_at"`
	UpdatedAt          time.Time `json:"updated_at"`
}

type Episode struct {
	ID            uint      `gorm:"primaryKey" json:"id"`
	DramaID       uint      `gorm:"not null" json:"drama_id"`
	EpisodeNumber int       `gorm:"not null" json:"episode_number"`
	TitleEN       string    `json:"title_en"`
	TitleES       string    `json:"title_es"`
	TitlePT       string    `json:"title_pt"`
	DescriptionEN string    `gorm:"type:text" json:"description_en"`
	DescriptionES string    `gorm:"type:text" json:"description_es"`
	DescriptionPT string    `gorm:"type:text" json:"description_pt"`
	VideoURL      string    `gorm:"not null" json:"video_url"`
	ThumbnailURL  string    `json:"thumbnail_url"`
	Duration      int       `gorm:"default:120" json:"duration"`
	IsFree        bool      `gorm:"default:false" json:"is_free"`
	Views         int64     `gorm:"default:0" json:"views"`
	SortOrder     int       `gorm:"default:0" json:"sort_order"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

type UserFavorite struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserID    uint      `gorm:"not null" json:"user_id"`
	DramaID   uint      `gorm:"not null" json:"drama_id"`
	Drama     Drama     `gorm:"foreignKey:DramaID" json:"drama"`
	CreatedAt time.Time `json:"created_at"`
}

type WatchHistory struct {
	ID            uint      `gorm:"primaryKey" json:"id"`
	UserID        uint      `gorm:"not null" json:"user_id"`
	DramaID       uint      `gorm:"not null" json:"drama_id"`
	Drama         Drama     `gorm:"foreignKey:DramaID" json:"drama"`
	EpisodeID     uint      `gorm:"not null" json:"episode_id"`
	Episode       Episode   `gorm:"foreignKey:EpisodeID" json:"episode"`
	Progress      int       `gorm:"default:0" json:"progress"`
	Completed     bool      `gorm:"default:false" json:"completed"`
	LastWatchedAt time.Time `json:"last_watched_at"`
	CreatedAt     time.Time `json:"created_at"`
}

type AdReward struct {
	ID         uint      `gorm:"primaryKey" json:"id"`
	UserID     uint      `gorm:"not null" json:"user_id"`
	EpisodeID  uint      `gorm:"not null" json:"episode_id"`
	AdNetwork  string    `gorm:"default:admob" json:"ad_network"`
	RewardType string    `gorm:"default:episode_unlock" json:"reward_type"`
	IPAddress  string    `json:"ip_address"`
	UserAgent  string    `json:"user_agent"`
	CreatedAt  time.Time `json:"created_at"`
}

type Subscription struct {
	ID                   uint      `gorm:"primaryKey" json:"id"`
	UserID               uint      `gorm:"not null" json:"user_id"`
	StripeSubscriptionID string    `gorm:"unique" json:"stripe_subscription_id"`
	StripePriceID        string    `json:"stripe_price_id"`
	PlanName             string    `json:"plan_name"`
	Amount               float64   `gorm:"type:decimal(10,2)" json:"amount"`
	Currency             string    `gorm:"default:USD" json:"currency"`
	Status               string    `gorm:"default:active" json:"status"` // active, cancelled, past_due, trialing
	CurrentPeriodStart   time.Time `json:"current_period_start"`
	CurrentPeriodEnd     time.Time `json:"current_period_end"`
	CancelledAt          *time.Time `json:"cancelled_at"`
	CreatedAt            time.Time `json:"created_at"`
	UpdatedAt            time.Time `json:"updated_at"`
}

type AdminUser struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	Email        string    `gorm:"unique;not null" json:"email"`
	PasswordHash string    `gorm:"not null" json:"-"`
	Name         string    `json:"name"`
	Role         string    `gorm:"default:editor" json:"role"` // super_admin, admin, editor
	IsActive     bool      `gorm:"default:true" json:"is_active"`
	LastLoginAt  *time.Time `json:"last_login_at"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}
