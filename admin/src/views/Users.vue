<template>
  <el-card>
    <template #header>
      <span>User Management</span>
    </template>
    
    <el-table :data="users" v-loading="loading">
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="email" label="Email" />
      <el-table-column prop="username" label="Username" />
      <el-table-column label="Premium" width="100">
        <template #default="{ row }">
          <el-tag :type="row.is_premium ? 'warning' : ''">{{ row.is_premium ? 'Yes' : 'No' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="Member Since" width="150">
        <template #default="{ row }">
          {{ new Date(row.created_at).toLocaleDateString() }}
        </template>
      </el-table-column>
    </el-table>
    
    <el-pagination
      v-model:current-page="page"
      v-model:page-size="limit"
      :total="total"
      layout="total, prev, pager, next"
      @current-change="loadUsers"
      style="margin-top: 20px; text-align: right;"
    />
  </el-card>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from '../utils/request'

const users = ref([])
const loading = ref(false)
const page = ref(1)
const limit = ref(20)
const total = ref(0)

const loadUsers = async () => {
  loading.value = true
  try {
    const { data } = await axios.get('/admin/users', {
      params: { page: page.value, limit: limit.value }
    })
    users.value = data.users
    total.value = data.total
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadUsers()
})
</script>
