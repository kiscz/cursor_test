import axios from 'axios'
import { ElMessage } from 'element-plus'

/** Ensure baseURL is a full URL when it looks like a hostname (e.g. "foo.up.railway.app/api" without protocol) */
function ensureFullUrl(base) {
  if (!base || typeof base !== 'string') return base
  const s = base.trim()
  if (s.startsWith('http://') || s.startsWith('https://') || s.startsWith('/')) return s
  // Hostname-like: contains a dot, no leading slash → prepend https://
  if (s.includes('.') && !s.startsWith('/')) return 'https://' + s
  return s
}

const rawBase = window.__ADMIN_API_BASE__ || import.meta.env.VITE_API_BASE_URL || '/api'
const request = axios.create({
  baseURL: ensureFullUrl(rawBase),
  timeout: 30000
})

// Request interceptor
request.interceptors.request.use(
  config => {
    const token = localStorage.getItem('admin_token')
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
          ElMessage.error('Please login')
          localStorage.removeItem('admin_token')
          window.location.hash = '#/login'
          break
        case 403:
          ElMessage.error('Access denied')
          break
        case 404:
          ElMessage.error('Resource not found')
          break
        case 500:
          ElMessage.error('Server error')
          break
        default:
          ElMessage.error(data.message || 'Request failed')
      }
    } else {
      const msg = error.code === 'ERR_NETWORK' ? 'Network error - check API URL and CORS' : (error.message || 'Network error')
      ElMessage.error(msg)
    }
    
    return Promise.reject(error)
  }
)

export default request
