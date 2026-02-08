import { createRouter, createWebHistory } from 'vue-router'
import { useUserStore } from '../stores/user'

const routes = [
  {
    path: '/',
    redirect: '/home'
  },
  {
    path: '/home',
    name: 'Home',
    component: () => import('../views/Home.vue'),
    meta: { keepAlive: true }
  },
  {
    path: '/browse',
    name: 'Browse',
    component: () => import('../views/Browse.vue'),
    meta: { keepAlive: true }
  },
  {
    path: '/drama/:id',
    name: 'DramaDetail',
    component: () => import('../views/DramaDetail.vue')
  },
  {
    path: '/watch/:dramaId/:episodeId',
    name: 'Watch',
    component: () => import('../views/Watch.vue')
  },
  {
    path: '/favorites',
    name: 'Favorites',
    component: () => import('../views/Favorites.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/profile',
    name: 'Profile',
    component: () => import('../views/Profile.vue')
  },
  {
    path: '/membership',
    name: 'Membership',
    component: () => import('../views/Membership.vue')
  },
  {
    path: '/membership/success',
    name: 'MembershipSuccess',
    component: () => import('../views/MembershipSuccess.vue')
  },
  {
    path: '/history',
    name: 'History',
    component: () => import('../views/History.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Login.vue')
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Navigation guard
router.beforeEach((to, from, next) => {
  const userStore = useUserStore()
  
  // 已登录用户访问登录页，重定向到目标页或首页
  if (to.path === '/login' && userStore.isLoggedIn) {
    const redirect = to.query.redirect || '/home'
    next(redirect)
    return
  }
  
  // 需要登录但未登录，跳转到登录页
  if (to.meta.requiresAuth && !userStore.isLoggedIn) {
    next({
      path: '/login',
      query: { redirect: to.fullPath }
    })
  } else {
    next()
  }
})

export default router
