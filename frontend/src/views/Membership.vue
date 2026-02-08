<template>
  <div class="membership">
    <van-nav-bar
      :title="$t('membership.title')"
      left-arrow
      @click-left="router.back()"
    />
    
    <div class="content">
      <!-- Current Subscription Status -->
      <div v-if="subscriptionStatus.is_active" class="subscription-status">
        <div class="status-header">
          <van-icon name="checked" color="#6C5CE7" size="24" />
          <h3>{{ $t('membership.active_subscription') }}</h3>
        </div>
        <p class="status-plan">{{ $t('membership.plan') }}: {{ subscriptionStatus.plan || 'Premium' }}</p>
        <p v-if="subscriptionStatus.current_period_end" class="status-date">
          {{ $t('membership.renews_on') }}: {{ formatDate(subscriptionStatus.current_period_end) }}
        </p>
        <van-button 
          type="warning" 
          block 
          @click="cancelSubscription"
          :loading="cancelling"
        >
          {{ $t('membership.cancel_subscription') }}
        </van-button>
      </div>
      
      <!-- Hero -->
      <div class="hero" v-if="!subscriptionStatus.is_active">
        <h1>{{ $t('membership.title') }}</h1>
        <p>{{ $t('membership.subtitle') }}</p>
      </div>
      
      <!-- Features -->
      <div class="features">
        <div class="feature-item">
          <van-icon name="checked" color="#6C5CE7" size="24" />
          <span>{{ $t('membership.features.ad_free') }}</span>
        </div>
        <div class="feature-item">
          <van-icon name="checked" color="#6C5CE7" size="24" />
          <span>{{ $t('membership.features.early_access') }}</span>
        </div>
        <div class="feature-item">
          <van-icon name="checked" color="#6C5CE7" size="24" />
          <span>{{ $t('membership.features.hd_quality') }}</span>
        </div>
        <div class="feature-item">
          <van-icon name="checked" color="#6C5CE7" size="24" />
          <span>{{ $t('membership.features.offline') }}</span>
        </div>
      </div>
      
      <!-- Plans -->
      <div class="plans" v-if="!subscriptionStatus.is_active">
        <div
          class="plan-card"
          :class="{ active: selectedPlan === 'monthly' }"
          @click="selectedPlan = 'monthly'"
        >
          <div class="plan-header">
            <h3>{{ $t('membership.monthly') }}</h3>
            <div class="plan-price">{{ $t('membership.price_monthly') }}</div>
          </div>
          <van-icon v-if="selectedPlan === 'monthly'" name="success" color="#6C5CE7" size="20" />
        </div>
        
        <div
          class="plan-card"
          :class="{ active: selectedPlan === 'yearly' }"
          @click="selectedPlan = 'yearly'"
        >
          <van-tag type="warning" class="save-badge">{{ $t('membership.save') }}</van-tag>
          <div class="plan-header">
            <h3>{{ $t('membership.yearly') }}</h3>
            <div class="plan-price">{{ $t('membership.price_yearly') }}</div>
          </div>
          <van-icon v-if="selectedPlan === 'yearly'" name="success" color="#6C5CE7" size="20" />
        </div>
      </div>
      
      <!-- Subscribe Button -->
      <van-button
        v-if="!subscriptionStatus.is_active"
        type="primary"
        block
        size="large"
        :loading="loading"
        @click="subscribe"
      >
        {{ $t('membership.subscribe') }}
      </van-button>
      
      <p class="terms">
        By subscribing, you agree to our Terms of Service and Privacy Policy.
        Cancel anytime.
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useUserStore } from '../stores/user'
import { showFailToast, showSuccessToast, showConfirmDialog } from 'vant'
import axios from '../utils/request'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const selectedPlan = ref('yearly')
const loading = ref(false)
const cancelling = ref(false)
const subscriptionStatus = ref({
  is_active: false,
  plan: null,
  current_period_end: null
})

const loadSubscriptionStatus = async () => {
  if (!userStore.isLoggedIn) return
  
  try {
    const { data } = await axios.get('/subscriptions/status')
    subscriptionStatus.value = {
      is_active: data.is_active || false,
      plan: data.plan || null,
      current_period_end: data.current_period_end || null
    }
    
    // Update user store premium status
    if (data.is_active) {
      userStore.user.is_premium = true
    }
  } catch (error) {
    console.error('Failed to load subscription status:', error)
  }
}

const subscribe = async () => {
  if (!userStore.isLoggedIn) {
    router.push({ path: '/login', query: { redirect: route.fullPath } })
    return
  }
  
  loading.value = true
  
  try {
    // Create Stripe checkout session
    const { data } = await axios.post('/subscriptions/create-checkout', {
      plan: selectedPlan.value
    })
    
    // Check if it's a development mode response
    if (data.message && data.message.includes('development mode')) {
      showSuccessToast('Subscription activated successfully!')
      // Reload subscription status and user info
      await loadSubscriptionStatus()
      await userStore.checkAuth()
      // Don't redirect, just stay on the page
    } else if (data.url) {
      // Production mode: Redirect to Stripe Checkout
      window.location.href = data.url
    } else {
      showFailToast('Failed to create checkout session')
    }
  } catch (error) {
    showFailToast(error.response?.data?.error || error.response?.data?.message || 'Failed to subscribe')
  } finally {
    loading.value = false
  }
}

const cancelSubscription = async () => {
  try {
    await showConfirmDialog({
      title: 'Cancel Subscription',
      message: 'Are you sure you want to cancel your subscription? You will lose access to premium features at the end of your billing period.'
    })
    
    cancelling.value = true
    await axios.post('/subscriptions/cancel')
    showSuccessToast('Subscription cancelled successfully')
    
    // Reload subscription status
    await loadSubscriptionStatus()
    
    // Update user store
    userStore.user.is_premium = false
    await userStore.checkAuth()
  } catch (error) {
    if (error !== 'cancel') {
      showFailToast(error.response?.data?.message || 'Failed to cancel subscription')
    }
  } finally {
    cancelling.value = false
  }
}

const formatDate = (dateString) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', { 
    year: 'numeric', 
    month: 'long', 
    day: 'numeric' 
  })
}

onMounted(() => {
  loadSubscriptionStatus()
})
</script>

<style scoped>
.membership {
  min-height: 100vh;
  background-color: var(--background-dark);
}

.content {
  padding: 24px;
}

.hero {
  text-align: center;
  margin-bottom: 40px;
}

.hero h1 {
  font-size: 32px;
  color: white;
  margin-bottom: 8px;
  background: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.hero p {
  font-size: 16px;
  color: #999;
}

.features {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-bottom: 32px;
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px;
  background-color: var(--background-card);
  border-radius: 8px;
  color: white;
}

.plans {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 24px;
}

.plan-card {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px;
  background-color: var(--background-card);
  border: 2px solid var(--border-color);
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.plan-card.active {
  border-color: var(--primary-color);
  background-color: rgba(108, 92, 231, 0.1);
}

.save-badge {
  position: absolute;
  top: -10px;
  right: 16px;
}

.plan-header h3 {
  font-size: 18px;
  color: white;
  margin-bottom: 4px;
}

.plan-price {
  font-size: 24px;
  font-weight: 600;
  color: var(--primary-color);
}

.terms {
  text-align: center;
  font-size: 12px;
  color: #666;
  margin-top: 16px;
  line-height: 1.5;
}

.subscription-status {
  padding: 20px;
  background: linear-gradient(135deg, rgba(108, 92, 231, 0.2), rgba(108, 92, 231, 0.1));
  border: 2px solid var(--primary-color);
  border-radius: 12px;
  margin-bottom: 24px;
}

.status-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
}

.status-header h3 {
  font-size: 18px;
  color: white;
  margin: 0;
}

.status-plan {
  font-size: 14px;
  color: #ccc;
  margin-bottom: 4px;
}

.status-date {
  font-size: 12px;
  color: #999;
  margin-bottom: 16px;
}
</style>
