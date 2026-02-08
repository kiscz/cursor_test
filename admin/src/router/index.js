import { createRouter, createWebHashHistory } from 'vue-router'
import { useAdminStore } from '../stores/admin'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Login.vue')
  },
  {
    path: '/',
    component: () => import('../layouts/MainLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        redirect: '/dashboard'
      },
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('../views/Dashboard.vue')
      },
      {
        path: 'dramas',
        name: 'Dramas',
        component: () => import('../views/Dramas.vue')
      },
      {
        path: 'dramas/create',
        name: 'CreateDrama',
        component: () => import('../views/DramaForm.vue')
      },
      {
        path: 'dramas/:id/edit',
        name: 'EditDrama',
        component: () => import('../views/DramaForm.vue')
      },
      {
        path: 'dramas/:id/episodes',
        name: 'Episodes',
        component: () => import('../views/Episodes.vue')
      },
      {
        path: 'categories',
        name: 'Categories',
        component: () => import('../views/Categories.vue')
      },
      {
        path: 'users',
        name: 'Users',
        component: () => import('../views/Users.vue')
      }
    ]
  }
]

// Hash 模式：地址为 #/login、#/dashboard，不依赖 nginx 回退到 index.html，避免空白页
const router = createRouter({
  history: createWebHashHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  const adminStore = useAdminStore()
  
  if (to.meta.requiresAuth && !adminStore.isLoggedIn) {
    next('/login')
  } else if (to.path === '/login' && adminStore.isLoggedIn) {
    next('/dashboard')
  } else {
    next()
  }
})

export default router
