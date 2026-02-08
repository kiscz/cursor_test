<template>
  <div id="app">
    <router-view v-slot="{ Component }">
      <keep-alive :include="['Home', 'Browse']">
        <component :is="Component" />
      </keep-alive>
    </router-view>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useUserStore } from './stores/user'

const userStore = useUserStore()

onMounted(() => {
  // Auto login from token
  userStore.checkAuth()
})
</script>

<style>
#app {
  width: 100%;
  min-height: 100vh;
  background-color: #0a0a0a;
}
</style>
