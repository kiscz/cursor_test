import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'

// 运行时加载 API 地址（支持部署后修改 config.json 无需重建）
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || '/api'
window.__ADMIN_API_BASE__ = apiBaseUrl

async function loadConfig() {
  try {
    const res = await fetch('/config.json?' + Date.now())
    if (res.ok) {
      const cfg = await res.json()
      if (cfg.apiBaseUrl) window.__ADMIN_API_BASE__ = cfg.apiBaseUrl
    }
  } catch (_) {}
}

const app = createApp(App)

// Register all icons
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

app.use(createPinia())
app.use(router)
app.use(ElementPlus)

loadConfig().then(() => app.mount('#app'))
