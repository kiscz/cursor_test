<template>
  <div>
    <el-card>
      <template #header>
        <div class="card-header">
          <span>Episodes - {{ drama?.title_en }}</span>
          <el-button type="primary" @click="showDialog = true">
            <el-icon><Plus /></el-icon>
            Add Episode
          </el-button>
        </div>
      </template>
      
      <el-table :data="episodes" v-loading="loading">
        <el-table-column prop="episode_number" label="#" width="80" />
        <el-table-column prop="title_en" label="Title" />
        <el-table-column prop="duration" label="Duration" width="100">
          <template #default="{ row }">
            {{ Math.floor(row.duration / 60) }}:{{ (row.duration % 60).toString().padStart(2, '0') }}
          </template>
        </el-table-column>
        <el-table-column label="Free" width="80">
          <template #default="{ row }">
            <el-tag :type="row.is_free ? 'success' : ''">{{ row.is_free ? 'Yes' : 'No' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="views" label="Views" width="100" />
        <el-table-column label="Actions" width="150">
          <template #default="{ row }">
            <el-button size="small" @click="handleEdit(row)">Edit</el-button>
            <el-button size="small" type="danger" @click="handleDelete(row.id)">Delete</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
    
    <!-- Episode Dialog -->
    <el-dialog v-model="showDialog" :title="editingEpisode ? 'Edit Episode' : 'Add Episode'" width="600px">
      <el-form ref="formRef" :model="episodeForm" label-width="120px">
        <el-form-item label="Episode #" required>
          <el-input-number v-model="episodeForm.episode_number" :min="1" />
        </el-form-item>
        <el-form-item label="Title (EN)">
          <el-input v-model="episodeForm.title_en" />
        </el-form-item>
        <el-form-item label="Video URL" required>
          <el-input v-model="episodeForm.video_url" placeholder="https://..." />
        </el-form-item>
        <el-form-item label="Duration (sec)">
          <el-input-number v-model="episodeForm.duration" :min="1" />
        </el-form-item>
        <el-form-item label="Free">
          <el-switch v-model="episodeForm.is_free" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showDialog = false">Cancel</el-button>
        <el-button type="primary" @click="handleSave">Save</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import axios from '../utils/request'
import { ElMessage, ElMessageBox } from 'element-plus'

const route = useRoute()
const dramaId = route.params.id

const drama = ref(null)
const episodes = ref([])
const loading = ref(false)
const showDialog = ref(false)
const editingEpisode = ref(null)

const episodeForm = ref({
  episode_number: 1,
  title_en: '',
  video_url: '',
  duration: 120,
  is_free: false
})

const loadDrama = async () => {
  const { data } = await axios.get(`/dramas/${dramaId}`)
  drama.value = data
}

const loadEpisodes = async () => {
  loading.value = true
  try {
    const { data } = await axios.get(`/dramas/${dramaId}/episodes`)
    episodes.value = data
  } finally {
    loading.value = false
  }
}

const handleEdit = (episode) => {
  editingEpisode.value = episode
  Object.assign(episodeForm.value, episode)
  showDialog.value = true
}

const handleSave = async () => {
  try {
    const payload = { ...episodeForm.value, drama_id: parseInt(dramaId) }
    
    if (editingEpisode.value) {
      await axios.put(`/admin/episodes/${editingEpisode.value.id}`, payload)
      ElMessage.success('Episode updated')
    } else {
      await axios.post('/admin/episodes', payload)
      ElMessage.success('Episode created')
    }
    
    showDialog.value = false
    editingEpisode.value = null
    loadEpisodes()
  } catch (error) {
    ElMessage.error('Operation failed')
  }
}

const handleDelete = async (id) => {
  try {
    await ElMessageBox.confirm('Delete this episode?', 'Warning', { type: 'warning' })
    await axios.delete(`/admin/episodes/${id}`)
    ElMessage.success('Episode deleted')
    loadEpisodes()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('Failed to delete')
    }
  }
}

onMounted(() => {
  loadDrama()
  loadEpisodes()
})
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
