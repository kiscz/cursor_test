<template>
  <div class="home">
    <!-- Search Bar -->
    <div class="search-bar">
      <van-search
        v-model="searchQuery"
        :placeholder="$t('home.search_placeholder')"
        @search="onSearch"
      />
    </div>

    <!-- Featured Banner -->
    <div class="featured-section" v-if="featuredDramas.length">
      <van-swipe :autoplay="5000" indicator-color="white" class="featured-swipe">
        <van-swipe-item v-for="drama in featuredDramas" :key="drama.id" @click="goToDrama(drama.id)">
          <div class="featured-item" :style="{ backgroundImage: `url(${drama.banner_url})` }">
            <div class="featured-overlay">
              <h2>{{ getTitle(drama) }}</h2>
              <p>{{ getDescription(drama) }}</p>
              <div class="featured-actions">
                <van-button type="primary" size="small" @click.stop="playDrama(drama)">
                  <van-icon name="play" /> {{ $t('drama.play') }}
                </van-button>
              </div>
            </div>
          </div>
        </van-swipe-item>
      </van-swipe>
    </div>

    <!-- Content Sections -->
    <van-pull-refresh v-model="refreshing" @refresh="onRefresh">
      <div class="content-sections">
        <!-- Continue Watching -->
        <section v-if="continueWatching.length" class="drama-section">
          <div class="section-header">
            <h3>{{ $t('home.continue_watching') }}</h3>
          </div>
          <div class="drama-row">
            <div
              v-for="item in continueWatching"
              :key="item.id"
              class="drama-card"
              @click="continueDrama(item)"
            >
              <div class="drama-poster">
                <van-image :src="item.drama.poster_url" fit="cover" />
                <div class="progress-bar">
                  <div class="progress" :style="{ width: item.progress + '%' }"></div>
                </div>
              </div>
              <p class="drama-title">{{ getTitle(item.drama) }}</p>
            </div>
          </div>
        </section>

        <!-- Trending -->
        <section v-if="trendingDramas.length" class="drama-section">
          <div class="section-header">
            <h3>{{ $t('home.trending') }}</h3>
          </div>
          <div class="drama-row">
            <div
              v-for="drama in trendingDramas"
              :key="drama.id"
              class="drama-card"
              @click="goToDrama(drama.id)"
            >
              <div class="drama-poster">
                <van-image :src="drama.poster_url" fit="cover" />
              </div>
              <p class="drama-title">{{ getTitle(drama) }}</p>
            </div>
          </div>
        </section>

        <!-- New Releases -->
        <section v-if="newReleases.length" class="drama-section">
          <div class="section-header">
            <h3>{{ $t('home.new_releases') }}</h3>
          </div>
          <div class="drama-row">
            <div
              v-for="drama in newReleases"
              :key="drama.id"
              class="drama-card"
              @click="goToDrama(drama.id)"
            >
              <div class="drama-poster">
                <van-image :src="drama.poster_url" fit="cover" />
                <span class="new-badge">NEW</span>
              </div>
              <p class="drama-title">{{ getTitle(drama) }}</p>
            </div>
          </div>
        </section>
      </div>
    </van-pull-refresh>

    <!-- Bottom Navigation -->
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
const { locale } = useI18n()

const active = ref(0)
const searchQuery = ref('')
const refreshing = ref(false)

const featuredDramas = ref([])
const continueWatching = ref([])
const trendingDramas = ref([])
const newReleases = ref([])

const getTitle = (drama) => {
  return drama[`title_${locale.value}`] || drama.title_en
}

const getDescription = (drama) => {
  const desc = drama[`description_${locale.value}`] || drama.description_en
  return desc?.substring(0, 100) + '...'
}

const loadData = async () => {
  try {
    const [featured, trending, newData, history] = await Promise.all([
      axios.get('/dramas/featured'),
      axios.get('/dramas/trending'),
      axios.get('/dramas/new'),
      axios.get('/watch-history/continue').catch(() => ({ data: [] }))
    ])
    
    featuredDramas.value = featured.data
    trendingDramas.value = trending.data
    newReleases.value = newData.data
    continueWatching.value = history.data
  } catch (error) {
    console.error('Failed to load data:', error)
  }
}

const onRefresh = async () => {
  await loadData()
  refreshing.value = false
}

const onSearch = () => {
  router.push(`/browse?q=${searchQuery.value}`)
}

const goToDrama = (id) => {
  router.push(`/drama/${id}`)
}

const playDrama = (drama) => {
  router.push(`/watch/${drama.id}/1`)
}

const continueDrama = (item) => {
  router.push(`/watch/${item.drama.id}/${item.episode_id}`)
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.home {
  padding-bottom: 50px;
  min-height: 100vh;
  background-color: var(--background-dark);
}

.search-bar {
  position: sticky;
  top: 0;
  z-index: 100;
  background-color: var(--background-dark);
}

.featured-section {
  margin-bottom: 24px;
}

.featured-swipe {
  height: 400px;
}

.featured-item {
  height: 400px;
  background-size: cover;
  background-position: center;
  position: relative;
}

.featured-overlay {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 24px 16px;
  background: linear-gradient(transparent, rgba(0, 0, 0, 0.9));
}

.featured-overlay h2 {
  font-size: 24px;
  margin-bottom: 8px;
  color: white;
}

.featured-overlay p {
  font-size: 14px;
  color: #ccc;
  margin-bottom: 16px;
}

.featured-actions {
  display: flex;
  gap: 12px;
}

.content-sections {
  padding: 0 0 16px 0;
}

.drama-section {
  margin-bottom: 32px;
}

.section-header {
  padding: 0 16px 12px 16px;
}

.section-header h3 {
  font-size: 18px;
  font-weight: 600;
  color: white;
}

.drama-row {
  display: flex;
  gap: 12px;
  padding: 0 16px;
  overflow-x: auto;
  scrollbar-width: none;
}

.drama-row::-webkit-scrollbar {
  display: none;
}

.drama-card {
  flex-shrink: 0;
  width: 120px;
  cursor: pointer;
}

.drama-poster {
  position: relative;
  width: 120px;
  height: 180px;
  border-radius: 8px;
  overflow: hidden;
  margin-bottom: 8px;
}

.drama-poster :deep(.van-image) {
  width: 100%;
  height: 100%;
}

.progress-bar {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 3px;
  background-color: rgba(255, 255, 255, 0.3);
}

.progress {
  height: 100%;
  background-color: var(--primary-color);
  transition: width 0.3s;
}

.new-badge {
  position: absolute;
  top: 8px;
  right: 8px;
  background-color: var(--primary-color);
  color: white;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 10px;
  font-weight: bold;
}

.drama-title {
  font-size: 13px;
  color: white;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}
</style>
