<template>
  <div class="favorites">
    <van-nav-bar :title="$t('nav.favorites')" />
    
    <van-pull-refresh v-model="refreshing" @refresh="onRefresh">
      <div class="content">
        <div v-if="favorites.length > 0" class="drama-grid">
          <div
            v-for="fav in favorites"
            :key="fav.id"
            class="drama-item"
            @click="goToDrama(fav.drama.id)"
          >
            <van-image class="drama-poster" :src="fav.drama.poster_url" fit="cover" />
            <div class="drama-info">
              <p class="drama-title">{{ getTitle(fav.drama) }}</p>
              <div class="drama-meta">
                <span>⭐ {{ fav.drama.rating }}</span>
              </div>
            </div>
          </div>
        </div>
        <van-empty v-else :description="$t('nav.favorites')" />
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
const { locale } = useI18n()

const active = ref(2)
const favorites = ref([])
const refreshing = ref(false)

const getTitle = (drama) => {
  return drama[`title_${locale.value}`] || drama.title_en
}

const loadFavorites = async () => {
  try {
    const { data } = await axios.get('/favorites')
    favorites.value = data
  } catch (error) {
    console.error('Failed to load favorites')
  }
}

const onRefresh = async () => {
  await loadFavorites()
  refreshing.value = false
}

const goToDrama = (id) => {
  router.push(`/drama/${id}`)
}

onMounted(() => {
  loadFavorites()
})
</script>

<style scoped>
.favorites {
  min-height: 100vh;
  background-color: var(--background-dark);
  padding-bottom: 50px;
}

.content {
  padding: 16px;
  min-height: calc(100vh - 46px - 50px);
}

.drama-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.drama-item {
  cursor: pointer;
}

.drama-poster {
  width: 100%;
  aspect-ratio: 2/3;
  border-radius: 8px;
  margin-bottom: 8px;
}

.drama-info {
  font-size: 12px;
}

.drama-title {
  color: white;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  margin-bottom: 4px;
}

.drama-meta {
  color: #999;
  font-size: 11px;
}
</style>
