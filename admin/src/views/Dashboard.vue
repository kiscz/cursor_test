<template>
  <div class="dashboard">
    <el-row :gutter="20">
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <el-icon class="stat-icon" color="#1890ff"><User /></el-icon>
            <div class="stat-info">
              <p class="stat-title">Total Users</p>
              <h2 class="stat-value">{{ stats.total_users }}</h2>
            </div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <el-icon class="stat-icon" color="#52c41a"><Trophy /></el-icon>
            <div class="stat-info">
              <p class="stat-title">Premium Users</p>
              <h2 class="stat-value">{{ stats.premium_users }}</h2>
            </div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <el-icon class="stat-icon" color="#722ed1"><VideoCamera /></el-icon>
            <div class="stat-info">
              <p class="stat-title">Total Dramas</p>
              <h2 class="stat-value">{{ stats.total_dramas }}</h2>
            </div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <el-icon class="stat-icon" color="#fa8c16"><View /></el-icon>
            <div class="stat-info">
              <p class="stat-title">Total Views</p>
              <h2 class="stat-value">{{ formatNumber(stats.total_views) }}</h2>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
    
    <el-row :gutter="20" style="margin-top: 20px;">
      <el-col :span="16">
        <el-card>
          <template #header>
            <span>Recent Activity</span>
          </template>
          <el-empty description="No recent activity" />
        </el-card>
      </el-col>
      
      <el-col :span="8">
        <el-card>
          <template #header>
            <span>Quick Actions</span>
          </template>
          <el-button type="primary" @click="$router.push('/dramas/create')" style="width: 100%; margin-bottom: 12px;">
            <el-icon><Plus /></el-icon>
            Add New Drama
          </el-button>
          <el-button @click="$router.push('/categories')" style="width: 100%; margin-bottom: 12px;">
            <el-icon><Menu /></el-icon>
            Manage Categories
          </el-button>
          <el-button @click="$router.push('/users')" style="width: 100%;">
            <el-icon><User /></el-icon>
            View Users
          </el-button>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from '../utils/request'

const stats = ref({
  total_users: 0,
  premium_users: 0,
  total_dramas: 0,
  total_episodes: 0,
  total_views: 0,
  active_subscriptions: 0
})

const loadStats = async () => {
  try {
    const { data } = await axios.get('/admin/stats')
    stats.value = data
  } catch (error) {
    console.error('Failed to load stats')
  }
}

const formatNumber = (num) => {
  if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M'
  if (num >= 1000) return (num / 1000).toFixed(1) + 'K'
  return num
}

onMounted(() => {
  loadStats()
})
</script>

<style scoped>
.stat-card {
  height: 120px;
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.stat-icon {
  font-size: 48px;
}

.stat-info {
  flex: 1;
}

.stat-title {
  margin: 0 0 8px 0;
  font-size: 14px;
  color: #8c8c8c;
}

.stat-value {
  margin: 0;
  font-size: 28px;
  font-weight: 600;
}
</style>
