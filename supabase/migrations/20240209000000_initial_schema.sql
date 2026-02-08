-- Supabase PostgreSQL Migration
-- Converted from MySQL schema

-- Enable UUID extension (optional, if you want to use UUIDs)
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    username VARCHAR(100),
    avatar_url VARCHAR(500),
    language VARCHAR(10) DEFAULT 'en',
    is_premium BOOLEAN DEFAULT FALSE,
    premium_expires_at TIMESTAMP NULL,
    stripe_customer_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_premium ON users(is_premium, premium_expires_at);

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
    id BIGSERIAL PRIMARY KEY,
    name_en VARCHAR(100) NOT NULL,
    name_es VARCHAR(100),
    name_pt VARCHAR(100),
    slug VARCHAR(100) UNIQUE NOT NULL,
    icon VARCHAR(255),
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_categories_slug ON categories(slug);
CREATE INDEX idx_categories_sort ON categories(sort_order);

-- Dramas table
CREATE TABLE IF NOT EXISTS dramas (
    id BIGSERIAL PRIMARY KEY,
    title_en VARCHAR(255) NOT NULL,
    title_es VARCHAR(255),
    title_pt VARCHAR(255),
    description_en TEXT,
    description_es TEXT,
    description_pt TEXT,
    poster_url VARCHAR(500),
    banner_url VARCHAR(500),
    trailer_url VARCHAR(500),
    category_id BIGINT,
    total_episodes INT DEFAULT 0,
    free_episodes INT DEFAULT 3,
    duration_per_episode INT DEFAULT 120,
    rating DECIMAL(3,2) DEFAULT 0.00,
    views BIGINT DEFAULT 0,
    is_featured BOOLEAN DEFAULT FALSE,
    is_premium_only BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    published_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_drama_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);

CREATE INDEX idx_dramas_category ON dramas(category_id);
CREATE INDEX idx_dramas_status ON dramas(status);
CREATE INDEX idx_dramas_featured ON dramas(is_featured);
CREATE INDEX idx_dramas_published ON dramas(published_at);

-- Episodes table
CREATE TABLE IF NOT EXISTS episodes (
    id BIGSERIAL PRIMARY KEY,
    drama_id BIGINT NOT NULL,
    episode_number INT NOT NULL,
    title_en VARCHAR(255),
    title_es VARCHAR(255),
    title_pt VARCHAR(255),
    description_en TEXT,
    description_es TEXT,
    description_pt TEXT,
    video_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    duration INT DEFAULT 120,
    is_free BOOLEAN DEFAULT FALSE,
    views BIGINT DEFAULT 0,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_episode_drama FOREIGN KEY (drama_id) REFERENCES dramas(id) ON DELETE CASCADE,
    CONSTRAINT unique_drama_episode UNIQUE (drama_id, episode_number)
);

CREATE INDEX idx_episodes_drama ON episodes(drama_id);
CREATE INDEX idx_episodes_number ON episodes(episode_number);

-- User favorites
CREATE TABLE IF NOT EXISTS user_favorites (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    drama_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_favorite_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_favorite_drama FOREIGN KEY (drama_id) REFERENCES dramas(id) ON DELETE CASCADE,
    CONSTRAINT unique_user_drama UNIQUE (user_id, drama_id)
);

CREATE INDEX idx_favorites_user ON user_favorites(user_id);
CREATE INDEX idx_favorites_drama ON user_favorites(drama_id);

-- Watch history
CREATE TABLE IF NOT EXISTS watch_histories (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    drama_id BIGINT NOT NULL,
    episode_id BIGINT NOT NULL,
    progress INT DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE,
    last_watched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_history_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_history_drama FOREIGN KEY (drama_id) REFERENCES dramas(id) ON DELETE CASCADE,
    CONSTRAINT fk_history_episode FOREIGN KEY (episode_id) REFERENCES episodes(id) ON DELETE CASCADE
);

CREATE INDEX idx_history_user ON watch_histories(user_id);
CREATE INDEX idx_history_drama ON watch_histories(drama_id);
CREATE INDEX idx_history_episode ON watch_histories(episode_id);
CREATE INDEX idx_history_watched ON watch_histories(last_watched_at);

-- Ad rewards
CREATE TABLE IF NOT EXISTS ad_rewards (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    episode_id BIGINT NOT NULL,
    ad_network VARCHAR(50) DEFAULT 'admob',
    reward_type VARCHAR(50) DEFAULT 'episode_unlock',
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reward_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_reward_episode FOREIGN KEY (episode_id) REFERENCES episodes(id) ON DELETE CASCADE
);

CREATE INDEX idx_rewards_user ON ad_rewards(user_id);
CREATE INDEX idx_rewards_episode ON ad_rewards(episode_id);
CREATE INDEX idx_rewards_user_episode ON ad_rewards(user_id, episode_id);

-- Subscriptions
CREATE TABLE IF NOT EXISTS subscriptions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    stripe_subscription_id VARCHAR(255) UNIQUE,
    stripe_price_id VARCHAR(255),
    plan_name VARCHAR(100),
    amount DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'past_due', 'trialing')),
    current_period_start TIMESTAMP,
    current_period_end TIMESTAMP,
    cancelled_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_subscription_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_stripe ON subscriptions(stripe_subscription_id);

-- Admin users
CREATE TABLE IF NOT EXISTS admin_users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100),
    role VARCHAR(20) DEFAULT 'editor' CHECK (role IN ('super_admin', 'admin', 'editor')),
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_admin_email ON admin_users(email);

-- Insert default admin user (password: admin123)
INSERT INTO admin_users (email, password_hash, name, role, is_active) VALUES 
('admin@example.com', '$2a$10$8YgAHzfCTl/5.CFjxX54ZuE5lOZGJlpImdV7Avbm3gVZD993yk5jW', 'Admin', 'admin', TRUE)
ON CONFLICT (email) DO NOTHING;

-- Insert sample categories
INSERT INTO categories (name_en, name_es, name_pt, slug, sort_order) VALUES 
('Romance', 'Romance', 'Romance', 'romance', 1),
('Drama', 'Drama', 'Drama', 'drama', 2),
('Thriller', 'Suspenso', 'Suspense', 'thriller', 3),
('Fantasy', 'Fantasía', 'Fantasia', 'fantasy', 4),
('Comedy', 'Comedia', 'Comédia', 'comedy', 5)
ON CONFLICT (slug) DO NOTHING;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dramas_updated_at BEFORE UPDATE ON dramas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_episodes_updated_at BEFORE UPDATE ON episodes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_admin_users_updated_at BEFORE UPDATE ON admin_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
