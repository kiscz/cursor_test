<template>
  <div class="history">
    <van-nav-bar :title="$t('profile.watch_history')" left-arrow @click-left="router.back()" />
    
    <van-pull-refresh v-model="refreshing" @refresh="onRefresh">
      <div class="content">
        <div v-if="history.length > 0" class="history-list">
          <div
            v-for="item in history"
            :key="item.id"
            class="history-item"
            @click="continueWatching(item)"
          >
            <van-image 
              class="drama-poster" 
              :src="item.drama?.poster_url || item.episode?.thumbnail_url" 
              fit="cover" 
            />
            <div class="history-info">
              <h3>{{ getTitle(item.drama) }}</h3>
              <p class="episode-info">
                {{ $t('drama.episode', { number: item.episode?.episode_number }) }}: {{ getEpisodeTitle(item.episode) }}
              </p>
              <div class="progress-info">
                <div class="progress-bar">
                  <div 
                    class="progress-fill" 
                    :style="{ width: getProgressPercent(item) + '%' }"
                  ></div>
                </div>
                <span class="progress-text">
                  {{ formatProgress(item) }}
                </span>
              </div>
              <p class="watched-time">{{ formatTime(item.last_watched_at) }}</p>
            </div>
            <van-icon name="play-circle-o" size="24" color="#6C5CE7" />
          </div>
        </div>
        <van-empty v-else :description="$t('profile.no_history')" />
      </div>
    </van-pull-refresh>
    
    <van-tabbar v-model="active" route>
      <van-tabbar-item to="/home" icon="wap-home">{{ $t('nav.home') }}</van-tabbar-item>
      <van-tabbar-item to="/browse" icon="apps-o">{{ $t('nav.browse') }}</van-tabbar-item>
      <van-tabbar-item to="/favorites" icon="star-o">{{ $t('nav.favorites') }}</van-tabbar-item>
      <van-tabbar-item to="/profile" icon="user-o">{{ $t('nav.profile') }}</van-tabbar-item>
    </van-tabbar>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import axios from '../utils/request'

const router = useRouter()
const { locale, t } = useI18n()

const active = ref(3)
const history = ref([])
const refreshing = ref(false)

const getTitle = (drama) => {
  if (!drama) return ''
  return drama[`title_${locale.value}`] || drama.title_en
}

const getEpisodeTitle = (episode) => {
  if (!episode) return ''
  return episode[`title_${locale.value}`] || episode.title_en || `Episode ${episode.episode_number}`
}

const getProgressPercent = (item) => {
  if (!item.episode || !item.episode.duration) return 0
  return Math.min(100, (item.progress / item.episode.duration) * 100)
}

const formatProgress = (item) => {
  if (!item.episode || !item.episode.duration) return '0%'
  const percent = getProgressPercent(item)
  if (item.completed) {
    return t('profile.completed')
  }
  return `${Math.round(percent)}%`
}

const formatTime = (timeString) => {
  if (!timeString) return ''
  const date = new Date(timeString)
  const now = new Date()
  const diff = now - date
  
  const minutes = Math.floor(diff / 60000)
  const hours = Math.floor(diff / 3600000)
  const days = Math.floor(diff / 86400000)
  
  if (minutes < 1) return t('profile.just_now')
  if (minutes < 60) return t('profile.minutes_ago', { count: minutes })
  if (hours < 24) return t('profile.hours_ago', { count: hours })
  if (days < 7) return t('profile.days_ago', { count: days })
  
  return date.toLocaleDateString()
}

const loadHistory = async () => {
  try {
    const { data } = await axios.get('/watch-history')
    history.value = data
  } catch (error) {
    console.error('Failed to load history:', error)
  }
}

const onRefresh = async () => {
  await loadHistory()
  refreshing.value = false
}

const continueWatching = (item) => {
  if (item.drama?.id && item.episode?.id) {
    router.push(`/watch/${item.drama.id}/${item.episode.id}`)
  }
}

onMounted(() => {
  loadHistory()
})
</script>

<style scoped>
.history {
  min-height: 100vh;
  background-color: var(--background-dark);
  padding-bottom: 50px;
}

.content {
  padding: 16px;
}

.history-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.history-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background-color: var(--background-card);
  border-radius: 8px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.history-item:active {
  background-color: #2a2a2a;
}

.drama-poster {
  width: 80px;
  height: 120px;
  border-radius: 8px;
  flex-shrink: 0;
}

.history-info {
  flex: 1;
  min-width: 0;
}

.history-info h3 {
  font-size: 16px;
  color: white;
  margin-bottom: 4px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.episode-info {
  font-size: 14px;
  color: #999;
  margin-bottom: 8px;
}

.progress-info {
  margin-bottom: 4px;
}

.progress-bar {
  width: 100%;
  height: 4px;
  background-color: rgba(255, 255, 255, 0.1);
  border-radius: 2px;
  overflow: hidden;
  margin-bottom: 4px;
}

.progress-fill {
  height: 100%;
  background-color: #6C5CE7;
  transition: width 0.3s;
}

.progress-text {
  font-size: 12px;
  color: #999;
}

.watched-time {
  font-size: 12px;
  color: #666;
  margin-top: 4px;
}
</style>
