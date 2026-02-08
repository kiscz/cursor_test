<template>
  <div class="profile">
    <van-nav-bar :title="$t('profile.my_profile')" />
    
    <div class="content" v-if="userStore.isLoggedIn">
      <!-- User Info -->
      <div class="user-card">
        <van-image
          class="avatar"
          :src="userStore.user?.avatar_url || defaultAvatar"
          round
          fit="cover"
        />
        <div class="user-info">
          <h3>{{ userStore.user?.username || userStore.user?.email }}</h3>
          <van-tag v-if="userStore.isPremium" type="warning">Premium</van-tag>
          <van-tag v-else>Free</van-tag>
        </div>
      </div>
      
      <!-- Premium Banner -->
      <div v-if="!userStore.isPremium" class="premium-banner" @click="goToMembership">
        <div class="banner-content">
          <h3>{{ $t('membership.title') }}</h3>
          <p>{{ $t('membership.subtitle') }}</p>
        </div>
        <van-icon name="arrow" />
      </div>
      
      <!-- Menu -->
      <van-cell-group class="menu-group">
        <van-cell :title="$t('profile.watch_history')" is-link @click="goToHistory" />
        <van-cell :title="$t('nav.favorites')" is-link to="/favorites" />
        <van-cell :title="$t('profile.settings')" is-link @click="showSettings = true" />
      </van-cell-group>
      
      <van-button class="logout-btn" block @click="handleLogout">
        {{ $t('profile.logout') }}
      </van-button>
    </div>
    
    <!-- Not Logged In -->
    <div class="content" v-else>
      <van-empty description="Please login to continue" />
      <van-button type="primary" block @click="goToLogin">
        {{ $t('auth.login') }}
      </van-button>
    </div>
    
    <!-- Settings Popup -->
    <van-popup v-model:show="showSettings" position="bottom" :style="{ height: '40%' }">
      <div class="settings-popup">
        <h3>{{ $t('profile.settings') }}</h3>
        <van-cell-group>
          <van-cell :title="$t('profile.language')">
            <template #right-icon>
              <van-dropdown-menu>
                <van-dropdown-item v-model="selectedLanguage" :options="languageOptions" @change="changeLanguage" />
              </van-dropdown-menu>
            </template>
          </van-cell>
        </van-cell-group>
      </div>
    </van-popup>
    
    <van-tabbar v-model="active" route>
      <van-tabbar-item to="/home" icon="wap-home">{{ $t('nav.home') }}</van-tabbar-item>
      <van-tabbar-item to="/browse" icon="apps-o">{{ $t('nav.browse') }}</van-tabbar-item>
      <van-tabbar-item to="/favorites" icon="star-o">{{ $t('nav.favorites') }}</van-tabbar-item>
      <van-tabbar-item to="/profile" icon="user-o">{{ $t('nav.profile') }}</van-tabbar-item>
    </van-tabbar>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useUserStore } from '../stores/user'
import { showSuccessToast, showFailToast } from 'vant'

const router = useRouter()
const route = useRoute()
const { locale, t } = useI18n()
const userStore = useUserStore()

// 默认头像：SVG data URI，不依赖外部网络
const defaultAvatar = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="80" height="80"%3E%3Ccircle cx="40" cy="40" r="40" fill="%236C5CE7"/%3E%3Ccircle cx="40" cy="32" r="12" fill="white"/%3E%3Cpath d="M20 55 Q20 45 40 45 Q60 45 60 55 L60 80 L20 80 Z" fill="white"/%3E%3C/svg%3E'

const active = ref(3)
const showSettings = ref(false)
const selectedLanguage = ref(locale.value)

const languageOptions = [
  { text: 'English', value: 'en' },
  { text: 'Español', value: 'es' },
  { text: 'Português', value: 'pt' }
]

const goToMembership = () => {
  router.push('/membership')
}

const goToHistory = () => {
  router.push('/history')
}

const goToLogin = () => {
  router.push({ path: '/login', query: { redirect: route.fullPath } })
}

const changeLanguage = (value) => {
  locale.value = value
  localStorage.setItem('language', value)
  location.reload()
}

const handleLogout = () => {
  if (!window.confirm(t('profile.logout_confirm'))) return
  userStore.logout()
  showSuccessToast(t('profile.logout_success'))
  router.replace({ path: '/login', query: { redirect: route.fullPath } })
}
</script>

<style scoped>
.profile {
  min-height: 100vh;
  background-color: var(--background-dark);
  padding-bottom: 50px;
}

.content {
  padding: 16px;
}

.user-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 24px;
  background-color: var(--background-card);
  border-radius: 12px;
  margin-bottom: 16px;
}

.avatar {
  width: 60px;
  height: 60px;
}

.user-info h3 {
  font-size: 18px;
  color: white;
  margin-bottom: 8px;
}

.premium-banner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px;
  background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
  border-radius: 12px;
  margin-bottom: 16px;
  cursor: pointer;
}

.banner-content h3 {
  font-size: 16px;
  color: white;
  margin-bottom: 4px;
}

.banner-content p {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.8);
}

.menu-group {
  margin-bottom: 24px;
}

.logout-btn {
  margin-top: 24px;
}

.settings-popup {
  padding: 24px;
}

.settings-popup h3 {
  font-size: 18px;
  color: var(--text-primary);
  margin-bottom: 16px;
}
</style>
