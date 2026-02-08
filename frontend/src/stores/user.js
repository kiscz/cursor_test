import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from '../utils/request'

export const useUserStore = defineStore('user', () => {
  const user = ref(null)
  const token = ref(localStorage.getItem('token') || '')
  
  const isLoggedIn = computed(() => !!token.value)
  const isPremium = computed(() => {
    if (!user.value) return false
    if (!user.value.is_premium) return false
    if (!user.value.premium_expires_at) return false
    return new Date(user.value.premium_expires_at) > new Date()
  })
  
  const login = async (email, password) => {
    const res = await axios.post('/auth/login', { email, password })
    const data = res?.data
    if (!data || !data.token) {
      const msg = data?.error || data?.message || 'Invalid response from server'
      throw new Error(msg)
    }
    token.value = data.token
    user.value = data.user || null
    localStorage.setItem('token', data.token)
    return data
  }
  
  const register = async (email, password, username) => {
    const { data } = await axios.post('/auth/register', { email, password, username })
    token.value = data.token
    user.value = data.user
    localStorage.setItem('token', data.token)
    return data
  }
  
  const logout = () => {
    token.value = ''
    user.value = null
    localStorage.removeItem('token')
  }
  
  const checkAuth = async () => {
    if (!token.value) return false
    try {
      const { data } = await axios.get('/auth/me')
      user.value = data
      return true
    } catch (error) {
      // If token is invalid, clear it but don't redirect here
      // The response interceptor will handle redirect for API calls
      // For checkAuth, we just silently fail and let the user stay on current page
      if (error.response?.status === 401) {
        logout()
      }
      return false
    }
  }
  
  const updateProfile = async (profile) => {
    const { data } = await axios.put('/users/profile', profile)
    user.value = { ...user.value, ...data }
    return data
  }
  
  return {
    user,
    token,
    isLoggedIn,
    isPremium,
    login,
    register,
    logout,
    checkAuth,
    updateProfile
  }
})
