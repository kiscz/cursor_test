<template>
  <div class="watch-page" @touchstart="handleTouchStart" @touchmove="handleTouchMove" @touchend="handleTouchEnd">
    <!-- Back Button -->
    <div class="back-button" @click="goBack">
      <van-icon name="arrow-left" size="24" color="#fff" />
    </div>
    
    <!-- Video Player -->
    <div class="player-container" v-if="episode" :key="episode.id">
      <video
        :id="playerId"
        class="video-js vjs-big-play-centered"
        controls
        preload="auto"
      />
    </div>


    <!-- Overlay Mask -->
    <div class="overlay-mask" v-if="showEpisodeSelector" @click="showEpisodeSelector = false"></div>

    <!-- Episode Selector - Expanded View -->
    <div class="episode-selector-expanded" v-if="showEpisodeSelector" @click.stop>
      <!-- Tabs: Synopsis / Episode Selection -->
      <div class="tabs-container">
        <div class="tabs">
          <div 
            class="tab" 
            :class="{ active: activeTab === 'synopsis' }"
            @click="activeTab = 'synopsis'"
          >
            简介
          </div>
        <div 
          class="tab" 
          :class="{ active: activeTab === 'episodes' }"
          @click="activeTab = 'episodes'"
        >
          选集
        </div>
        <div class="tab-close" @click.stop="showEpisodeSelector = false">
          <van-icon name="arrow-down" />
        </div>
      </div>

        <!-- Synopsis Tab Content -->
        <div class="tab-content" v-if="activeTab === 'synopsis'">
          <p class="description">{{ getDescription(drama) }}</p>
        </div>

        <!-- Episodes Tab Content -->
        <div class="tab-content episodes-content" v-if="activeTab === 'episodes'">
          <!-- Episode Range Selector -->
          <div class="episode-ranges" v-if="episodeRanges.length > 0">
            <div
              v-for="range in episodeRanges"
              :key="range.start"
              class="range-label"
              :class="{ active: currentRange.start === range.start }"
              @click="currentRange = range"
            >
              {{ range.start }}-{{ range.end }}
            </div>
          </div>

          <!-- Episode Grid -->
          <div class="episode-grid">
            <div
              v-for="ep in visibleEpisodes"
              :key="ep.id"
              class="episode-btn"
              :class="{ 
                active: ep.id === episode?.id,
                locked: !checkEpisodeAccess(ep)
              }"
              @click="changeEpisode(ep)"
            >
              <span class="episode-number">{{ ep.episode_number }}</span>
              <van-icon v-if="ep.id === episode?.id" name="play-circle-o" class="play-icon" />
              <van-icon v-if="!checkEpisodeAccess(ep)" name="lock" class="lock-icon" />
            </div>
          </div>
        </div>
      </div>

      <!-- Favorite Button -->
      <div class="action-bar">
        <van-button 
          type="primary" 
          block 
          round
          :icon="isFavorite ? 'star' : 'star-o'"
          @click="toggleFavorite"
        >
          {{ isFavorite ? '已收藏' : '收藏' }}
        </van-button>
      </div>
    </div>

    <!-- Episode Selector - Collapsed Button (Default) -->
    <div class="episode-selector-collapsed" v-if="!showEpisodeSelector" @click="showEpisodeSelector = true">
      <div class="collapsed-content">
        <span class="collapsed-text">选集{{ isCompleted ? '·已完结' : '' }}·全{{ episodes.length }}集</span>
        <van-icon name="arrow-up" class="expand-icon" />
      </div>
    </div>

    <!-- VIP Popup -->
    <van-popup v-model:show="showVipPopup" round :style="{ padding: '24px' }">
      <div class="vip-popup">
        <h3>{{ $t('player.premium_required') }}</h3>
        <p>{{ $t('player.watch_ads_or_subscribe') }}</p>
        <van-button 
          type="primary" 
          block 
          @click="watchAd()"
          :disabled="!userStore.isLoggedIn"
        >
          {{ userStore.isLoggedIn ? $t('player.watch_ad') : '请先登录' }}
        </van-button>
        <van-button block @click="goToMembership">{{ $t('player.subscribe') }}</van-button>
      </div>
    </van-popup>

    <!-- Ad Popup -->
    <van-popup v-model:show="showAdPopup" round :style="{ padding: '24px', textAlign: 'center' }" :close-on-click-overlay="false">
      <div class="ad-popup">
        <h3>正在播放广告</h3>
        <div class="ad-placeholder">
          <van-icon name="video-o" size="48" color="#999" />
          <p>广告内容</p>
        </div>
        <p class="ad-tip">请稍候，广告播放完成后将自动解锁</p>
      </div>
    </van-popup>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, computed, watch, nextTick } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useUserStore } from '../stores/user'
import { showFailToast, showSuccessToast, showLoadingToast, closeToast } from 'vant'
import videojs from 'video.js'
import axios from '../utils/request'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()
const { locale, t } = useI18n()

const playerId = `video-player-${Date.now()}`
let player = null
let progressInterval = null

const drama = ref(null)
const episode = ref(null)
const episodes = ref([])
const watchProgress = ref(0)
const showVipPopup = ref(false)
const showAdPopup = ref(false)
const adEpisodeId = ref(null)
const activeTab = ref('episodes')
const isFavorite = ref(false)
const currentRange = ref({ start: 1, end: 30 })
const showEpisodeSelector = ref(false) // 默认收起状态
const unlockedEpisodes = ref(new Set()) // 通过广告解锁的集数ID集合

// 触摸手势相关
const touchStartY = ref(0)
const touchStartX = ref(0)
const touchEndY = ref(0)
const isSwiping = ref(false)
const swipeStartTime = ref(0)
const SWIPE_THRESHOLD = 50 // 滑动阈值（像素）
const MIN_SWIPE_TIME = 100 // 最小滑动时间（毫秒），避免误触
const MAX_SWIPE_TIME = 500 // 最大滑动时间（毫秒）

// Episode ranges (每30集一组)
const episodeRanges = computed(() => {
  if (!episodes.value.length) return []
  const ranges = []
  const total = episodes.value.length
  for (let i = 1; i <= total; i += 30) {
    ranges.push({
      start: i,
      end: Math.min(i + 29, total)
    })
  }
  return ranges
})

// Visible episodes based on current range
const visibleEpisodes = computed(() => {
  if (!episodes.value.length) return []
  return episodes.value.filter(ep => 
    ep.episode_number >= currentRange.value.start && 
    ep.episode_number <= currentRange.value.end
  )
})

const isCompleted = computed(() => {
  // 只有当总集数等于已上架集数时才显示"已完结"
  if (!drama.value) return false
  const totalEpisodes = drama.value.total_episodes || 0
  // 优先使用后端返回的published_episodes，如果没有则使用episodes数组长度
  const publishedEpisodes = drama.value.published_episodes !== undefined 
    ? drama.value.published_episodes 
    : episodes.value.length
  return totalEpisodes > 0 && totalEpisodes === publishedEpisodes
})

const nextEpisode = computed(() => {
  if (!episode.value || !episodes.value.length) return null
  const currentIndex = episodes.value.findIndex(ep => ep.id === episode.value.id)
  return episodes.value[currentIndex + 1] || null
})

const prevEpisode = computed(() => {
  if (!episode.value || !episodes.value.length) return null
  const currentIndex = episodes.value.findIndex(ep => ep.id === episode.value.id)
  return episodes.value[currentIndex - 1] || null
})

const getTitle = (item) => {
  return item?.[`title_${locale.value}`] || item?.title_en
}

const getDescription = (item) => {
  return item?.[`description_${locale.value}`] || item?.description_en || '暂无简介'
}

const getEpisodeTitle = (item) => {
  return item?.[`title_${locale.value}`] || item?.title_en || `Episode ${item?.episode_number}`
}

const formatDuration = (seconds) => {
  const mins = Math.floor(seconds / 60)
  const secs = seconds % 60
  return `${mins}:${secs.toString().padStart(2, '0')}`
}

const checkEpisodeAccess = (ep) => {
  if (ep.is_free) return true
  if (userStore.isPremium) return true
  // 检查是否通过观看广告解锁
  if (userStore.isLoggedIn && unlockedEpisodes.value.has(ep.id)) return true
  return false
}

const loadData = async () => {
  try {
    const [dramaRes, episodeRes, episodesRes, favoriteRes] = await Promise.all([
      axios.get(`/dramas/${route.params.dramaId}`),
      axios.get(`/episodes/${route.params.episodeId}`),
      axios.get(`/dramas/${route.params.dramaId}/episodes`),
      userStore.isLoggedIn ? axios.get(`/favorites/check/${route.params.dramaId}`).catch(() => ({ data: { is_favorite: false } })) : Promise.resolve({ data: { is_favorite: false } })
    ])
    
    drama.value = dramaRes.data
    episode.value = episodeRes.data
    episodes.value = episodesRes.data.sort((a, b) => a.episode_number - b.episode_number)
    isFavorite.value = favoriteRes.data.is_favorite || false
    
    // Load unlocked episodes (for logged-in users)
    if (userStore.isLoggedIn && episodes.value.length > 0) {
      await loadUnlockedEpisodes()
    }
    
    // Set current range based on current episode
    if (episode.value) {
      const epNum = episode.value.episode_number
      const range = episodeRanges.value.find(r => epNum >= r.start && epNum <= r.end)
      if (range) {
        currentRange.value = range
      }
    }
    
    // Check access
    if (!checkEpisodeAccess(episode.value)) {
      // 设置要解锁的集数ID
      adEpisodeId.value = episode.value.id
      showVipPopup.value = true
      return
    }
    
    // 等 Vue 渲染出新的 video 元素后再初始化播放器
    await nextTick()
    setTimeout(() => {
      initOrUpdatePlayer()
    }, 50)
  } catch (error) {
    console.error('Load error:', error)
    showFailToast('Failed to load episode')
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

let initRetryCount = 0
const initOrUpdatePlayer = () => {
  const videoElement = document.getElementById(playerId)
  
  if (!videoElement) {
    if (initRetryCount < 5) {
      initRetryCount++
      setTimeout(initOrUpdatePlayer, 80)
    }
    return
  }
  initRetryCount = 0
  
  // 清理旧播放器（切换集数时 key 会重建 DOM，旧实例可能已失效）
  if (player) {
    try {
      if (!player.disposed) {
        player.pause()
        player.dispose()
      }
    } catch (e) {
      console.log('Dispose error:', e)
    }
    player = null
  }
  
  if (progressInterval) {
    clearInterval(progressInterval)
    progressInterval = null
  }
  
  try {
    // 在新 video 元素上创建播放器，设置合适的尺寸
    player = videojs(videoElement, {
      controls: true,
      autoplay: true, // 自动播放
      preload: 'auto',
      fluid: false, // 不使用 fluid，使用固定高度
      responsive: false, // 不使用 responsive
      fill: true, // 填充容器
      muted: false, // 不静音（如果需要自动播放，某些浏览器可能需要静音）
      sources: [{
        src: episode.value.video_url,
        type: 'video/mp4'
      }]
    })
    
    // 设置播放器尺寸和自动播放
    player.ready(() => {
      player.width('100%')
      player.height('100%')
      
      // 确保自动播放 - 多种方式尝试
      const tryAutoplay = () => {
        if (player && player.paused()) {
          player.play().catch(err => {
            console.log('Autoplay prevented:', err)
            // 如果自动播放被阻止，尝试静音播放
            if (!player.muted()) {
              player.muted(true)
              player.play().catch(() => {
                console.log('Autoplay with mute also prevented')
              })
            }
          })
        }
      }
      
      // 在多个事件中尝试自动播放
      player.one('loadedmetadata', tryAutoplay)
      player.one('canplay', tryAutoplay)
      
      // 延迟一下也尝试（防止某些情况下事件未触发）
      setTimeout(tryAutoplay, 300)
    })
    
    // Track progress
    player.on('timeupdate', () => {
      watchProgress.value = Math.floor(player.currentTime())
    })
    
    // Auto-save progress
    progressInterval = setInterval(() => {
      if (watchProgress.value > 0) {
        saveProgress()
      }
    }, 10000)
    
    // Handle ended
    player.on('ended', () => {
      saveProgress(true)
      if (nextEpisode.value) {
        setTimeout(() => playNext(), 3000)
      }
    })
    
    // Load saved progress
    setTimeout(() => {
      loadProgress()
    }, 500)
    
  } catch (error) {
    console.error('Player init error:', error)
  }
}

const loadProgress = async () => {
  try {
    const { data } = await axios.get(`/watch-history/${episode.value.id}`)
    if (data.progress && data.progress > 5 && player) {
      player.currentTime(data.progress)
    }
    return Promise.resolve()
  } catch (error) {
    // No progress
    return Promise.resolve()
  }
}

const saveProgress = async (completed = false) => {
  if (!episode.value) return
  try {
    await axios.post('/watch-history', {
      drama_id: parseInt(route.params.dramaId),
      episode_id: parseInt(route.params.episodeId),
      progress: watchProgress.value,
      completed
    })
  } catch (error) {
    console.error('Save progress error:', error)
  }
}

const playNext = () => {
  if (nextEpisode.value) {
    if (!checkEpisodeAccess(nextEpisode.value)) {
      adEpisodeId.value = nextEpisode.value.id
      showVipPopup.value = true
      return
    }
    saveProgress(true)
    // 切换集数并自动播放（通过路由切换触发重新加载和自动播放）
    router.push(`/watch/${drama.value.id}/${nextEpisode.value.id}`)
  }
}

const playPrev = () => {
  if (prevEpisode.value) {
    if (!checkEpisodeAccess(prevEpisode.value)) {
      adEpisodeId.value = prevEpisode.value.id
      showVipPopup.value = true
      return
    }
    saveProgress(true)
    // 切换集数并自动播放（通过路由切换触发重新加载和自动播放）
    router.push(`/watch/${drama.value.id}/${prevEpisode.value.id}`)
  }
}

const changeEpisode = (ep) => {
  if (ep.id === episode.value?.id) return
  
  if (!checkEpisodeAccess(ep)) {
    // 保存要解锁的集数ID
    adEpisodeId.value = ep.id
    showVipPopup.value = true
    return
  }
  
  saveProgress()
  // 切换集数时自动收起选集区域
  showEpisodeSelector.value = false
  // 切换集数并自动播放
  router.push(`/watch/${drama.value.id}/${ep.id}`).then(() => {
    // 路由切换后，loadData 会重新加载数据并初始化播放器
    // 播放器初始化时会自动播放（autoplay: true）
  })
}

const toggleFavorite = async () => {
  if (!userStore.isLoggedIn) {
    router.push({ path: '/login', query: { redirect: route.fullPath } })
    return
  }
  
  try {
    if (isFavorite.value) {
      await axios.delete(`/favorites/${route.params.dramaId}`)
      isFavorite.value = false
      showSuccessToast('已取消收藏')
    } else {
      await axios.post(`/favorites/${route.params.dramaId}`)
      isFavorite.value = true
      showSuccessToast('已收藏')
    }
  } catch (error) {
    showFailToast('操作失败')
  }
}

const watchAd = async () => {
  if (!userStore.isLoggedIn) {
    router.push({ path: '/login', query: { redirect: route.fullPath } })
    return
  }
  
  // 确定要解锁的集数ID - 优先使用 adEpisodeId（用户点击的集数），如果没有则使用当前集数
  const targetEpisodeId = adEpisodeId.value || episode.value?.id
  if (!targetEpisodeId) {
    showFailToast('无法确定要解锁的集数')
    return
  }
  
  showVipPopup.value = false
  showAdPopup.value = true
  
  try {
    // 等待3秒模拟广告播放
    await new Promise(resolve => setTimeout(resolve, 3000))
    
    // 调用后端API记录广告奖励
    const response = await axios.post('/ads/reward', {
      episode_id: targetEpisodeId,
      ad_network: 'web',
      reward_type: 'episode_unlock'
    })
    
    if (response.data.unlocked) {
      // 添加到已解锁集合
      unlockedEpisodes.value.add(targetEpisodeId)
      
      showAdPopup.value = false
      showSuccessToast('广告播放完成！集数已解锁')
      
      // 如果解锁的是当前集数，重新加载数据以播放视频
      // 如果解锁的是其他集数，跳转到该集数
      if (episode.value && episode.value.id === targetEpisodeId) {
        await loadData()
      } else {
        // 跳转到解锁的集数
        const unlockedEpisode = episodes.value.find(ep => ep.id === targetEpisodeId)
        if (unlockedEpisode) {
          router.push(`/watch/${drama.value.id}/${targetEpisodeId}`)
        }
      }
      
      // 清除 adEpisodeId
      adEpisodeId.value = null
    } else {
      showFailToast('解锁失败，请重试')
    }
  } catch (error) {
    console.error('Watch ad error:', error)
    showAdPopup.value = false
    showFailToast(error.response?.data?.error || '观看广告失败')
  }
}

const goToMembership = () => {
  router.push('/membership')
}

const goBack = () => {
  // 如果有drama数据，返回drama详情页，否则返回上一页
  if (drama.value?.id) {
    router.push(`/drama/${drama.value.id}`)
  } else {
    router.back()
  }
}

// 触摸手势处理
const handleTouchStart = (e) => {
  // 如果选集界面展开，不处理手势
  if (showEpisodeSelector.value) return
  
  // 如果点击的是视频播放器的控制栏，不处理手势
  const target = e.target
  if (target.closest('.vjs-control-bar') || target.closest('.vjs-big-play-button')) {
    return
  }
  
  const touch = e.touches[0]
  touchStartY.value = touch.clientY
  touchStartX.value = touch.clientX
  swipeStartTime.value = Date.now()
  isSwiping.value = false
}

const handleTouchMove = (e) => {
  if (showEpisodeSelector.value) return
  
  const touch = e.touches[0]
  const deltaY = touch.clientY - touchStartY.value
  const deltaX = Math.abs(touch.clientX - touchStartX.value)
  
  // 确保是垂直滑动（垂直距离大于水平距离）
  if (Math.abs(deltaY) > deltaX && Math.abs(deltaY) > 10) {
    isSwiping.value = true
    // 只在明显滑动时阻止默认行为
    if (Math.abs(deltaY) > 20) {
      e.preventDefault()
    }
  }
}

const handleTouchEnd = (e) => {
  if (showEpisodeSelector.value) {
    isSwiping.value = false
    return
  }
  
  if (!isSwiping.value) {
    return
  }
  
  const touch = e.changedTouches[0]
  touchEndY.value = touch.clientY
  const touchEndX = touch.clientX
  const swipeTime = Date.now() - swipeStartTime.value
  
  const deltaY = touchEndY.value - touchStartY.value
  const deltaX = Math.abs(touchEndX - touchStartX.value)
  const absDeltaY = Math.abs(deltaY)
  
  // 确保是垂直滑动、距离足够、时间合理
  if (
    absDeltaY > deltaX && 
    absDeltaY > SWIPE_THRESHOLD &&
    swipeTime >= MIN_SWIPE_TIME &&
    swipeTime <= MAX_SWIPE_TIME
  ) {
    if (deltaY < 0) {
      // 向上滑动 - 下一集
      playNext()
    } else {
      // 向下滑动 - 上一集
      playPrev()
    }
  }
  
  isSwiping.value = false
}

// 切换集数时先销毁旧播放器，再加载新数据（避免 dispose 后 DOM 错乱）
watch(
  () => route.params.episodeId,
  (newId, oldId) => {
    if (newId && newId !== oldId) {
      watchProgress.value = 0
      if (player) {
        try {
          if (!player.disposed) player.dispose()
        } catch (e) {}
        player = null
      }
      if (progressInterval) {
        clearInterval(progressInterval)
        progressInterval = null
      }
      loadData()
    }
  }
)

onMounted(() => {
  loadData()
})

onBeforeUnmount(() => {
  if (progressInterval) {
    clearInterval(progressInterval)
  }
  if (player) {
    saveProgress()
    try {
      player.dispose()
    } catch (e) {
      console.log('Cleanup error:', e)
    }
  }
})
</script>

<style scoped>
.watch-page {
  height: 100vh;
  background-color: var(--background-dark);
  display: flex;
  flex-direction: column;
  overflow: hidden; /* 防止页面滚动 */
  touch-action: pan-y; /* 允许垂直滚动，但优化触摸响应 */
  -webkit-overflow-scrolling: touch;
  position: relative;
}

/* Back Button */
.back-button {
  position: absolute;
  top: 16px;
  left: 16px;
  z-index: 1000;
  width: 40px;
  height: 40px;
  background-color: rgba(0, 0, 0, 0.6);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background-color 0.2s;
}

.back-button:active {
  background-color: rgba(0, 0, 0, 0.8);
}

/* Player Container - 适应手机屏幕，撑满到底部按钮处 */
.player-container {
  width: 100%;
  background-color: #000;
  position: relative;
  touch-action: pan-y; /* 允许垂直手势 */
  height: calc(100vh - 60px); /* 100vh 减去底部按钮高度 */
  display: flex;
  align-items: center;
  justify-content: center;
}

.video-js {
  width: 100% !important;
  height: 100% !important;
  max-width: 100%;
  max-height: 100%;
}

/* Video.js 内部元素也需要撑满 */
.video-js .vjs-tech {
  width: 100% !important;
  height: 100% !important;
  object-fit: contain;
}


/* Episode Selector - Collapsed Button */
.episode-selector-collapsed {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background-color: #2a2a2a;
  border-top: 1px solid #333;
  padding: 14px 16px;
  z-index: 100;
  cursor: pointer;
  transition: background-color 0.2s;
  border-radius: 12px 12px 0 0;
  flex-shrink: 0; /* 防止按钮被压缩 */
}

.episode-selector-collapsed:active {
  background-color: #333;
}

.collapsed-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.collapsed-text {
  font-size: 14px;
  color: #ccc;
  flex: 1;
  font-weight: 400;
}

.expand-icon {
  font-size: 14px;
  color: #999;
  transition: transform 0.2s;
  margin-left: 8px;
}

/* Episode Selector - Expanded View */
.episode-selector-expanded {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background-color: var(--background-dark);
  max-height: 80vh;
  overflow-y: auto;
  z-index: 200;
  box-shadow: 0 -4px 20px rgba(0, 0, 0, 0.5);
  animation: slideUp 0.3s ease-out;
  border-radius: 12px 12px 0 0;
  -webkit-overflow-scrolling: touch; /* iOS 平滑滚动 */
}

@keyframes slideUp {
  from {
    transform: translateY(100%);
  }
  to {
    transform: translateY(0);
  }
}

/* Tabs Container */
.tabs-container {
  background-color: #1a1a1a;
  margin-bottom: 8px;
}

.tabs {
  display: flex;
  align-items: center;
  border-bottom: 1px solid #333;
  padding: 0 16px;
  position: relative;
}

.tab-close {
  margin-left: auto;
  padding: 12px 8px;
  cursor: pointer;
  color: #999;
  transition: color 0.2s;
}

.tab-close:active {
  color: white;
}

.tab-close .van-icon {
  font-size: 18px;
}

.tab {
  padding: 12px 16px;
  font-size: 16px;
  color: #999;
  cursor: pointer;
  position: relative;
  transition: color 0.2s;
}

.tab.active {
  color: white;
  font-weight: 600;
}

.tab.active::after {
  content: '';
  position: absolute;
  bottom: -1px;
  left: 16px;
  right: 16px;
  height: 2px;
  background-color: var(--primary-color, #ff6b35);
}

.tab-content {
  padding: 16px;
  min-height: 200px;
}

.description {
  color: #ccc;
  font-size: 14px;
  line-height: 1.6;
  margin: 0;
}

/* Episodes Content */
.episodes-content {
  padding: 16px;
}

.episode-ranges {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
  padding-bottom: 16px;
  border-bottom: 1px solid #333;
}

.range-label {
  padding: 6px 12px;
  font-size: 14px;
  color: #999;
  cursor: pointer;
  border-radius: 4px;
  transition: all 0.2s;
}

.range-label.active {
  color: white;
  background-color: #333;
}

.episode-grid {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 12px;
  max-height: 400px;
  overflow-y: auto;
}

.episode-btn {
  aspect-ratio: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #2a2a2a;
  border-radius: 8px;
  cursor: pointer;
  position: relative;
  transition: all 0.2s;
  border: 2px solid transparent;
}

.episode-btn:active {
  transform: scale(0.95);
}

.episode-btn.active {
  background-color: var(--primary-color, #ff6b35);
  border-color: var(--primary-color, #ff6b35);
}

.episode-btn.locked {
  opacity: 0.5;
}

.episode-number {
  font-size: 14px;
  font-weight: 500;
  color: white;
}

.episode-btn.active .episode-number {
  color: white;
}

.play-icon {
  position: absolute;
  top: 4px;
  right: 4px;
  font-size: 12px;
  color: white;
}

.lock-icon {
  position: absolute;
  top: 4px;
  right: 4px;
  font-size: 12px;
  color: #ffd700;
}

/* Action Bar */
.action-bar {
  padding: 12px 16px;
  background-color: #1a1a1a;
  border-top: 1px solid #333;
}

.action-bar :deep(.van-button) {
  height: 44px;
  font-size: 16px;
}

/* VIP Popup */
.vip-popup {
  text-align: center;
}

.vip-popup h3 {
  margin-bottom: 12px;
  color: var(--primary-color);
}

.vip-popup p {
  margin-bottom: 20px;
  color: #666;
}

.vip-popup .van-button {
  margin-bottom: 12px;
}

/* Ad Popup */
.ad-popup {
  text-align: center;
}

.ad-popup h3 {
  margin-bottom: 20px;
  color: white;
}

.ad-placeholder {
  background-color: #2a2a2a;
  border-radius: 8px;
  padding: 40px 20px;
  margin-bottom: 16px;
  min-height: 200px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.ad-placeholder p {
  margin-top: 12px;
  color: #999;
  font-size: 14px;
}

.ad-tip {
  color: #999;
  font-size: 12px;
  margin-top: 12px;
}

/* Scrollbar styling */
.episode-grid::-webkit-scrollbar {
  width: 4px;
}

.episode-grid::-webkit-scrollbar-track {
  background: #1a1a1a;
}

.episode-grid::-webkit-scrollbar-thumb {
  background: #555;
  border-radius: 2px;
}

.episode-grid::-webkit-scrollbar-thumb:hover {
  background: #777;
}
</style>
