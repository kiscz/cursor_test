<template>
  <div class="login-page">
    <van-nav-bar
      title="Short Drama"
      left-arrow
      @click-left="router.back()"
    />
    
    <div class="login-content">
      <div class="logo">
        <h1>🎬</h1>
        <h2>Short Drama</h2>
      </div>
      
      <van-form @submit="onSubmit">
        <van-cell-group inset>
          <van-field
            v-model="form.email"
            :label="$t('auth.email')"
            placeholder="your@email.com"
            type="email"
            :rules="[{ required: true, message: 'Email is required' }]"
          />
          <van-field
            v-model="form.password"
            :label="$t('auth.password')"
            :type="showPassword ? 'text' : 'password'"
            placeholder="Enter password"
            :rules="[{ required: true, message: 'Password is required' }]"
          >
            <template #right-icon>
              <van-icon :name="showPassword ? 'eye-o' : 'closed-eye'" @click="showPassword = !showPassword" />
            </template>
          </van-field>
        </van-cell-group>
        
        <div class="form-footer">
          <van-button type="primary" native-type="submit" block :loading="loading">
            {{ isLogin ? $t('auth.login') : $t('auth.register') }}
          </van-button>
          
          <div class="switch-mode">
            <span v-if="isLogin">{{ $t('auth.no_account') }}</span>
            <span v-else>{{ $t('auth.have_account') }}</span>
            <a @click="isLogin = !isLogin">
              {{ isLogin ? $t('auth.register') : $t('auth.login') }}
            </a>
          </div>
        </div>
      </van-form>
      
      <div class="divider">
        <span>OR</span>
      </div>
      
      <van-button block @click="skipLogin">Continue as Guest</van-button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useUserStore } from '../stores/user'
import { showSuccessToast, showFailToast } from 'vant'

const router = useRouter()
const route = useRoute()
const { t } = useI18n()
const userStore = useUserStore()

const isLogin = ref(true)
const showPassword = ref(false)
const loading = ref(false)

const form = ref({
  email: '',
  password: ''
})

const onSubmit = async () => {
  loading.value = true
  
  try {
    if (isLogin.value) {
      await userStore.login(form.value.email, form.value.password)
      // 确保 token 已设置
      if (!userStore.token || !localStorage.getItem('token')) {
        showFailToast('Login failed: no token received')
        return
      }
      showSuccessToast(t('auth.login_success'))
      const redirect = (typeof route.query.redirect === 'string' && route.query.redirect) ? route.query.redirect : '/home'
      const path = redirect.startsWith('/') ? redirect : '/' + redirect
      // 使用 router.push 让路由守卫处理，如果失败再用 location.replace
      try {
        await router.push(path)
      } catch (e) {
        window.location.replace(path)
      }
    } else {
      await userStore.register(form.value.email, form.value.password, form.value.email.split('@')[0])
      userStore.logout() // 注册后不保持登录，让用户再登录一次
      isLogin.value = true
      showSuccessToast(t('auth.register_success') || 'Register success, please login')
      // 留在登录页，不 push，当前已是登录表单
    }
  } catch (error) {
    const msg = error.message || error.response?.data?.error || error.response?.data?.message || 'Authentication failed'
    showFailToast(msg)
  } finally {
    loading.value = false
  }
}

const skipLogin = () => {
  router.push('/home')
}

// Auto-check auth when component mounts
onMounted(async () => {
  // If token exists, try to validate it
  if (userStore.token) {
    const isValid = await userStore.checkAuth()
    if (isValid && userStore.isLoggedIn) {
      // Token is valid, redirect to home or redirect query param
      const redirect = route.query.redirect || '/home'
      router.push(redirect)
    }
    // If invalid, token is already cleared by checkAuth, stay on login page
  }
})
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  background-color: var(--background-dark);
}

.login-content {
  padding: 40px 24px;
}

.logo {
  text-align: center;
  margin-bottom: 48px;
}

.logo h1 {
  font-size: 64px;
  margin-bottom: 8px;
}

.logo h2 {
  font-size: 24px;
  color: white;
  font-weight: 600;
}

.form-footer {
  margin-top: 24px;
  padding: 0 16px;
}

.switch-mode {
  margin-top: 16px;
  text-align: center;
  font-size: 14px;
  color: #999;
}

.switch-mode a {
  color: var(--primary-color);
  margin-left: 8px;
  cursor: pointer;
}

.divider {
  display: flex;
  align-items: center;
  margin: 32px 0;
  color: #666;
}

.divider::before,
.divider::after {
  content: '';
  flex: 1;
  border-bottom: 1px solid var(--border-color);
}

.divider span {
  padding: 0 16px;
  font-size: 12px;
}
</style>
