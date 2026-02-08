<template>
  <div>
    <el-card>
      <template #header>
        <div class="card-header">
          <span>Drama Management</span>
          <el-button type="primary" @click="$router.push('/dramas/create')">
            <el-icon><Plus /></el-icon>
            Add Drama
          </el-button>
        </div>
      </template>
      
      <!-- 筛选器 -->
      <el-row :gutter="20" style="margin-bottom: 20px;">
        <el-col :span="6">
          <el-select v-model="statusFilter" placeholder="All Status" @change="loadDramas" clearable>
            <el-option label="All Status" value="" />
            <el-option label="Published" value="published" />
            <el-option label="Draft" value="draft" />
            <el-option label="Ongoing" value="ongoing" />
            <el-option label="Completed" value="completed" />
            <el-option label="Archived" value="archived" />
          </el-select>
        </el-col>
        <el-col :span="18">
          <el-input 
            v-model="searchQuery" 
            placeholder="Search dramas..." 
            @change="loadDramas"
            clearable
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </el-col>
      </el-row>
      
      <el-table :data="dramas" v-loading="loading">
        <el-table-column label="Poster" width="100">
          <template #default="{ row }">
            <el-image :src="row.poster_url" fit="cover" style="width: 60px; height: 90px; border-radius: 4px;" />
          </template>
        </el-table-column>
        
        <el-table-column prop="title_en" label="Title" />
        
        <el-table-column prop="category.name_en" label="Category" width="120" />
        
        <el-table-column label="Episodes" width="100">
          <template #default="{ row }">
            {{ row.total_episodes }}
          </template>
        </el-table-column>
        
        <el-table-column prop="views" label="Views" width="100" />
        
        <el-table-column prop="status" label="Status" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">{{ row.status }}</el-tag>
          </template>
        </el-table-column>
        
        <el-table-column label="Actions" width="200" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="$router.push(`/dramas/${row.id}/episodes`)">Episodes</el-button>
            <el-button size="small" @click="$router.push(`/dramas/${row.id}/edit`)">Edit</el-button>
            <el-button size="small" type="danger" @click="handleDelete(row.id)">Delete</el-button>
          </template>
        </el-table-column>
      </el-table>
      
      <el-pagination
        v-model:current-page="page"
        v-model:page-size="limit"
        :total="total"
        layout="total, prev, pager, next"
        @current-change="loadDramas"
        style="margin-top: 20px; text-align: right;"
      />
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from '../utils/request'
import { ElMessage, ElMessageBox } from 'element-plus'

const dramas = ref([])
const loading = ref(false)
const page = ref(1)
const limit = ref(20)
const total = ref(0)
const statusFilter = ref('')
const searchQuery = ref('')

const getStatusType = (status) => {
  const types = {
    published: 'success',
    draft: 'info',
    ongoing: 'primary',
    completed: 'success',
    archived: 'warning'
  }
  return types[status] || 'info'
}

const loadDramas = async () => {
  loading.value = true
  try {
    const params = { 
      page: page.value, 
      limit: limit.value
    }
    
    // 添加可选的筛选参数
    if (statusFilter.value) {
      params.status = statusFilter.value
    }
    if (searchQuery.value) {
      params.q = searchQuery.value
    }
    
    const { data } = await axios.get('/admin/dramas', { params })
    dramas.value = data.data || data
    total.value = data.total || 0
  } catch (error) {
    ElMessage.error('Failed to load dramas')
    console.error('Load dramas error:', error)
  } finally {
    loading.value = false
  }
}

const handleDelete = async (id) => {
  try {
    await ElMessageBox.confirm('Are you sure you want to delete this drama?', 'Warning', {
      type: 'warning'
    })
    
    await axios.delete(`/admin/dramas/${id}`)
    ElMessage.success('Drama deleted')
    loadDramas()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('Failed to delete drama')
    }
  }
}

onMounted(() => {
  loadDramas()
})
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
