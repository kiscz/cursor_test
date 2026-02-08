import axios from 'axios'
import { showFailToast } from 'vant'

const request = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
  timeout: 30000
})

// Request interceptor
request.interceptors.request.use(
  config => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  error => {
    return Promise.reject(error)
  }
)

// Response interceptor
request.interceptors.response.use(
  response => {
    return response
  },
  error => {
    if (error.response) {
      const { status, data } = error.response
      
      switch (status) {
        case 401:
          // Only redirect if not already on login page to avoid redirect loops
          if (window.location.pathname !== '/login') {
            showFailToast('Please login')
            localStorage.removeItem('token')
            const redirect = encodeURIComponent(window.location.pathname + window.location.search)
            window.location.href = redirect ? `/login?redirect=${redirect}` : '/login'
          }
          break
        case 403:
          showFailToast('Access denied')
          break
        case 404:
          showFailToast('Resource not found')
          break
        case 500:
          showFailToast('Server error')
          break
        default:
          showFailToast(data.message || 'Request failed')
      }
    } else {
      showFailToast('Network error')
    }
    
    return Promise.reject(error)
  }
)

export default request
