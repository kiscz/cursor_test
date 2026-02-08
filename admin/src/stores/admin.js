import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from '../utils/request'

export const useAdminStore = defineStore('admin', () => {
  const admin = ref(null)
  const token = ref(localStorage.getItem('admin_token') || '')
  
  const isLoggedIn = computed(() => !!token.value)
  
  const login = async (email, password) => {
    const { data } = await axios.post('/admin/auth/login', { email, password })
    token.value = data.token
    admin.value = data.admin
    localStorage.setItem('admin_token', data.token)
    return data
  }
  
  const logout = () => {
    token.value = ''
    admin.value = null
    localStorage.removeItem('admin_token')
  }
  
  const checkAuth = async () => {
    if (!token.value) return false
    try {
      // If needed, add a /admin/auth/me endpoint
      return true
    } catch (error) {
      logout()
      return false
    }
  }
  
  return {
    admin,
    token,
    isLoggedIn,
    login,
    logout,
    checkAuth
  }
})
