<template>
  <div class="browse">
    <van-nav-bar :title="$t('nav.browse')" />
    
    <!-- Search -->
    <van-search
      v-model="searchQuery"
      :placeholder="$t('home.search_placeholder')"
      @search="onSearch"
    />
    
    <!-- Categories -->
    <van-tabs v-model:active="activeCategory" @change="onCategoryChange">
      <van-tab v-for="cat in categories" :key="cat.id" :title="getCategoryName(cat)" />
    </van-tabs>
    
    <!-- Drama Grid -->
    <van-pull-refresh v-model="refreshing" @refresh="onRefresh">
      <van-list
        v-model:loading="loading"
        :finished="finished"
        :finished-text="$t('common.loading')"
        @load="onLoad"
      >
        <div class="drama-grid">
          <div
            v-for="drama in dramas"
            :key="drama.id"
            class="drama-item"
            @click="goToDrama(drama.id)"
          >
            <van-image class="drama-poster" :src="drama.poster_url" fit="cover" />
            <div class="drama-info">
              <p class="drama-title">{{ getTitle(drama) }}</p>
              <div class="drama-meta">
                <span>⭐ {{ drama.rating }}</span>
                <span>{{ formatViews(drama.views) }}</span>
              </div>
            </div>
          </div>
        </div>
        <van-empty v-if="dramas.length === 0 && !loading" description="No dramas found" />
      </van-list>
    </van-pull-refresh>
    
    <van-tabbar v-model="tabActive" route>
      <van-tabbar-item to="/home" icon="wap-home">{{ $t('nav.home') }}</van-tabbar-item>
      <van-tabbar-item to="/browse" icon="apps-o">{{ $t('nav.browse') }}</van-tabbar-item>
      <van-tabbar-item to="/favorites" icon="star-o">{{ $t('nav.favorites') }}</van-tabbar-item>
      <van-tabbar-item to="/profile" icon="user-o">{{ $t('nav.profile') }}</van-tabbar-item>
    </van-tabbar>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import axios from '../utils/request'

const router = useRouter()
const route = useRoute()
const { locale } = useI18n()

const tabActive = ref(1)
const activeCategory = ref(0)
const searchQuery = ref(route.query.q || '')
const categories = ref([])
const dramas = ref([])
const loading = ref(false)
const finished = ref(false)
const refreshing = ref(false)
const page = ref(1)

const getCategoryName = (cat) => {
  return cat[`name_${locale.value}`] || cat.name_en
}

const getTitle = (drama) => {
  return drama[`title_${locale.value}`] || drama.title_en
}

const formatViews = (views) => {
  if (views >= 1000000) return (views / 1000000).toFixed(1) + 'M'
  if (views >= 1000) return (views / 1000).toFixed(1) + 'K'
  return views
}

const loadCategories = async () => {
  try {
    const { data } = await axios.get('/categories')
    categories.value = [{ id: 0, name_en: 'All', name_es: 'Todos', name_pt: 'Todos' }, ...data]
  } catch (error) {
    console.error('Failed to load categories')
  }
}

const loadDramas = async (reset = false) => {
  if (loading.value) return
  
  loading.value = true
  
  if (reset) {
    page.value = 1
    dramas.value = []
    finished.value = false
  }
  
  try {
    const params = {
      page: page.value,
      limit: 20
    }
    
    if (activeCategory.value > 0) {
      params.category_id = categories.value[activeCategory.value].id
    }
    
    if (searchQuery.value) {
      params.q = searchQuery.value
    }
    
    const { data } = await axios.get('/dramas', { params })
    
    if (reset) {
      dramas.value = data
    } else {
      dramas.value.push(...data)
    }
    
    if (data.length < 20) {
      finished.value = true
    }
    
    page.value++
  } catch (error) {
    console.error('Failed to load dramas')
  } finally {
    loading.value = false
  }
}

const onLoad = () => {
  loadDramas()
}

const onRefresh = async () => {
  await loadDramas(true)
  refreshing.value = false
}

const onCategoryChange = () => {
  loadDramas(true)
}

const onSearch = () => {
  loadDramas(true)
}

const goToDrama = (id) => {
  router.push(`/drama/${id}`)
}

onMounted(() => {
  loadCategories()
  loadDramas(true)
})
</script>

<style scoped>
.browse {
  min-height: 100vh;
  background-color: var(--background-dark);
  padding-bottom: 50px;
}

.drama-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  padding: 16px;
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
  display: flex;
  gap: 8px;
  color: #999;
  font-size: 11px;
}
</style>
