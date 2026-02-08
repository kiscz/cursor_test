<template>
  <div class="membership-success">
    <van-nav-bar title="Subscription Success" left-arrow @click-left="goToMembership" />
    
    <div class="content">
      <div class="success-icon">
        <van-icon name="success" size="64" color="#6C5CE7" />
      </div>
      
      <h2>{{ $t('membership.success_title') }}</h2>
      <p>{{ $t('membership.success_message') }}</p>
      
      <van-button type="primary" block size="large" @click="goToMembership">
        {{ $t('membership.back_to_membership') }}
      </van-button>
      
      <van-button block @click="goToHome">
        {{ $t('nav.home') }}
      </van-button>
    </div>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '../stores/user'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const goToMembership = () => {
  router.push('/membership')
}

const goToHome = () => {
  router.push('/home')
}

onMounted(async () => {
  // Refresh user info to get updated premium status
  if (userStore.isLoggedIn) {
    await userStore.checkAuth()
  }
})
</script>

<style scoped>
.membership-success {
  min-height: 100vh;
  background-color: var(--background-dark);
}

.content {
  padding: 60px 24px;
  text-align: center;
}

.success-icon {
  margin-bottom: 24px;
}

h2 {
  font-size: 24px;
  color: white;
  margin-bottom: 12px;
}

p {
  font-size: 16px;
  color: #999;
  margin-bottom: 32px;
  line-height: 1.6;
}

.van-button {
  margin-bottom: 12px;
}
</style>
