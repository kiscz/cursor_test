<template>
  <div class="drama-detail">
    <!-- Loading State -->
    <div v-if="loading" class="loading-state">
      <van-loading type="spinner" color="#6C5CE7" vertical>
        加载中...
      </van-loading>
    </div>
    
    <!-- Error State -->
    <div v-else-if="error" class="error-state">
      <van-nav-bar title="加载失败" left-arrow @click-left="router.back()" />
      <div class="error-content">
        <van-icon name="warning-o" size="48" color="#999" />
        <p>{{ error }}</p>
        <van-button type="primary" @click="loadData">重试</van-button>
      </div>
    </div>
    
    <!-- Content -->
    <template v-else-if="drama">
      <!-- Header -->
      <van-nav-bar
        :title="getTitle(drama)"
        left-arrow
        @click-left="router.back()"
      />

    <!-- Banner -->
    <div class="drama-banner" :style="{ backgroundImage: `url(${drama.banner_url || drama.poster_url})` }">
      <div class="banner-overlay">
        <div class="drama-info">
          <van-image class="drama-poster-large" :src="drama.poster_url" fit="cover" />
          <div class="drama-meta">
            <h1>{{ getTitle(drama) }}</h1>
            <div class="meta-row">
              <van-tag type="primary">{{ drama.category?.name_en }}</van-tag>
              <span class="rating">⭐ {{ drama.rating }}</span>
              <span class="views">{{ formatViews(drama.views) }} {{ $t('drama.views') }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Actions -->
    <div class="actions">
      <van-button type="primary" block size="large" @click="playFirstEpisode">
        <van-icon name="play" /> {{ $t('drama.play') }}
      </van-button>
      <div class="action-buttons">
        <van-button
          :icon="isFavorite ? 'star' : 'star-o'"
          :type="isFavorite ? 'warning' : 'default'"
          @click="toggleFavorite"
        >
          {{ isFavorite ? $t('drama.remove_from_favorites') : $t('drama.add_to_favorites') }}
        </van-button>
      </div>
    </div>

    <!-- Description -->
    <div class="section">
      <h3>{{ $t('drama.description') }}</h3>
      <p>{{ getDescription(drama) }}</p>
    </div>

    <!-- Episodes -->
    <div class="section">
      <h3>{{ $t('drama.episodes') }}</h3>
      <div class="episodes-list">
        <div
          v-for="episode in episodes"
          :key="episode.id"
          class="episode-item"
          :class="{ locked: !checkEpisodeAccess(episode) }"
          @click="playEpisode(episode)"
        >
          <div class="episode-thumb-wrapper">
            <van-image class="episode-thumb" :src="episode.thumbnail_url || drama.poster_url" fit="cover" />
            <div v-if="!checkEpisodeAccess(episode)" class="lock-overlay">
              <van-icon name="lock" size="24" color="#FFD700" />
            </div>
          </div>
          <div class="episode-info">
            <div class="episode-title">
              {{ $t('drama.episode', { number: episode.episode_number }) }}: {{ getEpisodeTitle(episode) }}
            </div>
            <div class="episode-meta">
              <span>{{ formatDuration(episode.duration) }}</span>
              <van-tag v-if="episode.is_free" type="success" size="mini">{{ $t('drama.free') }}</van-tag>
              <van-tag v-else-if="checkEpisodeAccess(episode) && unlockedEpisodes.has(episode.id)" type="info" size="mini">
                <van-icon name="checked" size="12" style="margin-right: 2px;" />
                已解锁
              </van-tag>
              <van-tag v-else-if="!checkEpisodeAccess(episode)" type="warning" size="mini">
                <van-icon name="lock" size="12" style="margin-right: 2px;" />
                {{ $t('drama.premium') }}
              </van-tag>
            </div>
          </div>
          <van-icon 
            :name="!checkEpisodeAccess(episode) ? 'lock' : 'play-circle-o'" 
            size="24" 
            :color="!checkEpisodeAccess(episode) ? '#FFD700' : '#6C5CE7'" 
          />
        </div>
      </div>
    </div>

    <!-- Upgrade prompt for non-premium users -->
    <van-popup v-model:show="showUpgradePopup" round closeable>
      <div class="upgrade-popup">
        <h2>{{ $t('membership.title') }}</h2>
        <p>{{ $t('membership.subtitle') }}</p>
        <van-button type="primary" block @click="goToMembership">
          {{ $t('membership.subscribe') }}
        </van-button>
        <van-button block @click="watchAd">
          {{ $t('drama.watch_ad') }}
        </van-button>
      </div>
    </van-popup>
    
    <!-- Bottom Navigation -->
    <van-tabbar v-model="tabActive" route>
      <van-tabbar-item to="/home" icon="wap-home">{{ $t('nav.home') }}</van-tabbar-item>
      <van-tabbar-item to="/browse" icon="apps-o">{{ $t('nav.browse') }}</van-tabbar-item>
      <van-tabbar-item to="/favorites" icon="star-o">{{ $t('nav.favorites') }}</van-tabbar-item>
      <van-tabbar-item to="/profile" icon="user-o">{{ $t('nav.profile') }}</van-tabbar-item>
    </van-tabbar>
    </template>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useUserStore } from '../stores/user'
import { showSuccessToast, showFailToast, showLoadingToast, closeToast } from 'vant'
import axios from '../utils/request'

const router = useRouter()
const route = useRoute()
const { locale } = useI18n()
const userStore = useUserStore()

const drama = ref(null)
const episodes = ref([])
const isFavorite = ref(false)
const showUpgradePopup = ref(false)
const selectedEpisode = ref(null)
const unlockedEpisodes = ref(new Set()) // 通过广告解锁的集数ID集合
const loading = ref(true)
const error = ref(null)
const tabActive = ref(0) // Tabbar active index

const getTitle = (item) => {
  return item[`title_${locale.value}`] || item.title_en
}

const getDescription = (item) => {
  return item[`description_${locale.value}`] || item.description_en
}

const getEpisodeTitle = (episode) => {
  return episode[`title_${locale.value}`] || episode.title_en || `Episode ${episode.episode_number}`
}

const formatViews = (views) => {
  if (views >= 1000000) return (views / 1000000).toFixed(1) + 'M'
  if (views >= 1000) return (views / 1000).toFixed(1) + 'K'
  return views
}

const formatDuration = (seconds) => {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins}:${secs.toString().padStart(2, '0')}`
}

const loadData = async () => {
  loading.value = true
  error.value = null
  
  try {
    console.log('Loading drama:', route.params.id)
    const [dramaRes, episodesRes, favoriteRes] = await Promise.all([
      axios.get(`/dramas/${route.params.id}`),
      axios.get(`/dramas/${route.params.id}/episodes`),
      axios.get(`/favorites/check/${route.params.id}`).catch(() => ({ data: { is_favorite: false } }))
    ])
    
    console.log('Drama data loaded:', dramaRes.data)
    drama.value = dramaRes.data
    episodes.value = episodesRes.data
    isFavorite.value = favoriteRes.data.is_favorite
    
    // Load unlocked episodes (for logged-in users)
    if (userStore.isLoggedIn && episodes.value.length > 0) {
      await loadUnlockedEpisodes()
    }
    
    console.log('Data loaded successfully, drama:', drama.value, 'episodes:', episodes.value.length)
  } catch (err) {
    console.error('Failed to load drama:', err)
    error.value = err.response?.data?.error || err.message || '加载失败，请重试'
    showFailToast(error.value)
  } finally {
    loading.value = false
    console.log('Loading finished, loading:', loading.value, 'error:', error.value, 'drama:', drama.value)
  }
}

// 加载用户已解锁的集数
const loadUnlockedEpisodes = async () => {
  if (!userStore.isLoggedIn || !episodes.value.length) return
  
  try {
    const checkPromises = episodes.value
      .filter(ep => !ep.is_free) // 只检查非免费集数
      .map(ep => 
        axios.get(`/ads/check/${ep.id}`)
          .then(res => ({ id: ep.id, unlocked: res.data.unlocked }))
          .catch(() => ({ id: ep.id, unlocked: false }))
      )
    
    const results = await Promise.all(checkPromises)
    results.forEach(result => {
      if (result.unlocked) {
        unlockedEpisodes.value.add(result.id)
      }
    })
  } catch (error) {
    console.error('Failed to load unlocked episodes:', error)
  }
}

// 检查集数是否可以访问
const checkEpisodeAccess = (ep) => {
  if (ep.is_free) return true
  if (userStore.isPremium) return true
  // 检查是否通过观看广告解锁
  if (userStore.isLoggedIn && unlockedEpisodes.value.has(ep.id)) return true
  return false
}

const toggleFavorite = async () => {
  if (!userStore.isLoggedIn) {
    router.push({ path: '/login', query: { redirect: route.fullPath } })
    return
  }
  
  try {
    if (isFavorite.value) {
      await axios.delete(`/favorites/${route.params.id}`)
      isFavorite.value = false
      showSuccessToast('Removed from favorites')
    } else {
      await axios.post(`/favorites/${route.params.id}`)
      isFavorite.value = true
      showSuccessToast('Added to favorites')
    }
  } catch (error) {
    showFailToast('Operation failed')
  }
}

const playFirstEpisode = () => {
  if (episodes.value.length > 0) {
    // 找到第一个可访问的集数
    const firstAccessible = episodes.value.find(ep => checkEpisodeAccess(ep)) || episodes.value[0]
    playEpisode(firstAccessible)
  }
}

const playEpisode = async (episode) => {
  // Check if user can watch this episode
  if (checkEpisodeAccess(episode)) {
    router.push(`/watch/${drama.value.id}/${episode.id}`)
    return
  }
  
  // Show upgrade or ad popup
  selectedEpisode.value = episode
  showUpgradePopup.value = true
}

const goToMembership = () => {
  router.push('/membership')
}

const watchAd = async () => {
  if (!userStore.isLoggedIn) {
    router.push({ path: '/login', query: { redirect: route.fullPath } })
    return
  }
  
  if (!selectedEpisode.value) {
    showFailToast('无法确定要解锁的集数')
    return
  }
  
  showUpgradePopup.value = false
  showLoadingToast('正在播放广告...')
  
  try {
    // 等待3秒模拟广告播放
    await new Promise(resolve => setTimeout(resolve, 3000))
    
    // 调用后端API记录广告奖励
    const response = await axios.post('/ads/reward', {
      episode_id: selectedEpisode.value.id,
      ad_network: 'web',
      reward_type: 'episode_unlock'
    })
    
    if (response.data.unlocked) {
      // 添加到已解锁集合
      unlockedEpisodes.value.add(selectedEpisode.value.id)
      
      closeToast()
      showSuccessToast('广告播放完成！集数已解锁')
      // 跳转到播放页面
      router.push(`/watch/${drama.value.id}/${selectedEpisode.value.id}`)
    } else {
      closeToast()
      showFailToast('解锁失败，请重试')
    }
  } catch (error) {
    console.error('Watch ad error:', error)
    closeToast()
    showFailToast(error.response?.data?.error || '观看广告失败')
  }
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.drama-detail {
  min-height: 100vh;
  background-color: var(--background-dark);
  padding-bottom: 70px; /* Space for tabbar */
}

.drama-banner {
  height: 300px;
  background-size: cover;
  background-position: center;
  position: relative;
}

.banner-overlay {
  height: 100%;
  background: linear-gradient(transparent, rgba(0, 0, 0, 0.95));
  display: flex;
  align-items: flex-end;
  padding: 20px 16px;
}

.drama-info {
  display: flex;
  gap: 16px;
  width: 100%;
}

.drama-poster-large {
  width: 100px;
  height: 150px;
  border-radius: 8px;
  flex-shrink: 0;
}

.drama-meta {
  flex: 1;
}

.drama-meta h1 {
  font-size: 20px;
  color: white;
  margin-bottom: 8px;
}

.meta-row {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  font-size: 12px;
  color: #999;
}

.rating {
  color: #FFD700;
}

.actions {
  padding: 16px;
}

.action-buttons {
  display: flex;
  gap: 8px;
  margin-top: 12px;
}

.section {
  padding: 16px;
  border-top: 1px solid var(--border-color);
}

.section h3 {
  font-size: 16px;
  color: white;
  margin-bottom: 12px;
}

.section p {
  font-size: 14px;
  color: #999;
  line-height: 1.6;
}

.episodes-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.episode-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background-color: var(--background-card);
  border-radius: 8px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.episode-item.locked {
  opacity: 0.8;
}

.episode-item:active {
  background-color: #2a2a2a;
}

.episode-thumb-wrapper {
  position: relative;
  width: 80px;
  height: 60px;
  flex-shrink: 0;
}

.episode-thumb {
  width: 100%;
  height: 100%;
  border-radius: 4px;
}

.lock-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.6);
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.episode-info {
  flex: 1;
}

.episode-title {
  font-size: 14px;
  color: white;
  margin-bottom: 4px;
}

.episode-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: #999;
}

.upgrade-popup {
  padding: 32px 24px 24px 24px;
  text-align: center;
}

.upgrade-popup h2 {
  font-size: 20px;
  color: var(--text-primary);
  margin-bottom: 12px;
}

.upgrade-popup p {
  font-size: 14px;
  color: var(--text-secondary);
  margin-bottom: 24px;
}

.upgrade-popup .van-button {
  margin-bottom: 12px;
}

.error-state {
  min-height: 100vh;
  background-color: var(--background-dark);
}

.error-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  text-align: center;
}

.error-content p {
  color: #999;
  font-size: 14px;
  margin: 16px 0 24px 0;
}

.error-content .van-button {
  min-width: 120px;
}

.loading-state {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: var(--background-dark);
  padding: 100px 20px;
}
</style>
