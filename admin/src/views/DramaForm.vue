<template>
  <el-card>
    <template #header>
      <span>{{ isEdit ? 'Edit Drama' : 'Create Drama' }}</span>
    </template>
    
    <el-form ref="formRef" :model="form" :rules="rules" label-width="150px">
      <el-tabs>
        <el-tab-pane label="Basic Info">
          <el-form-item label="Title (EN)" prop="title_en">
            <el-input v-model="form.title_en" />
          </el-form-item>
          
          <el-form-item label="Title (ES)">
            <el-input v-model="form.title_es" />
          </el-form-item>
          
          <el-form-item label="Title (PT)">
            <el-input v-model="form.title_pt" />
          </el-form-item>
          
          <el-form-item label="Description (EN)" prop="description_en">
            <el-input v-model="form.description_en" type="textarea" :rows="4" />
          </el-form-item>
          
          <el-form-item label="Category" prop="category_id">
            <el-select v-model="form.category_id" placeholder="Select category">
              <el-option v-for="cat in categories" :key="cat.id" :label="cat.name_en" :value="cat.id" />
            </el-select>
          </el-form-item>
          
          <el-form-item label="Poster URL" prop="poster_url">
            <el-input v-model="form.poster_url" placeholder="https://..." />
          </el-form-item>
          
          <el-form-item label="Banner URL">
            <el-input v-model="form.banner_url" placeholder="https://..." />
          </el-form-item>
          
          <el-form-item label="Status" prop="status">
            <el-radio-group v-model="form.status">
              <el-radio label="draft">Draft</el-radio>
              <el-radio label="published">Published</el-radio>
              <el-radio label="archived">Archived</el-radio>
            </el-radio-group>
          </el-form-item>
          
          <el-form-item label="Featured">
            <el-switch v-model="form.is_featured" />
          </el-form-item>
          
          <el-form-item label="Premium Only">
            <el-switch v-model="form.is_premium_only" />
          </el-form-item>
          
          <el-form-item label="Free Episodes">
            <el-input-number v-model="form.free_episodes" :min="0" />
          </el-form-item>
        </el-tab-pane>
      </el-tabs>
      
      <el-form-item>
        <el-button type="primary" @click="handleSubmit" :loading="loading">
          {{ isEdit ? 'Update' : 'Create' }}
        </el-button>
        <el-button @click="$router.back()">Cancel</el-button>
      </el-form-item>
    </el-form>
  </el-card>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import axios from '../utils/request'
import { ElMessage } from 'element-plus'

const router = useRouter()
const route = useRoute()

const isEdit = computed(() => !!route.params.id)

const formRef = ref(null)
const loading = ref(false)
const categories = ref([])

const form = ref({
  title_en: '',
  title_es: '',
  title_pt: '',
  description_en: '',
  description_es: '',
  description_pt: '',
  poster_url: '',
  banner_url: '',
  category_id: null,
  free_episodes: 3,
  is_featured: false,
  is_premium_only: false,
  status: 'draft'
})

const rules = {
  title_en: [{ required: true, message: 'Please enter title', trigger: 'blur' }],
  description_en: [{ required: true, message: 'Please enter description', trigger: 'blur' }],
  category_id: [{ required: true, message: 'Please select category', trigger: 'change' }],
  poster_url: [{ required: true, message: 'Please enter poster URL', trigger: 'blur' }]
}

const loadCategories = async () => {
  const { data } = await axios.get('/categories')
  categories.value = data
}

const loadDrama = async () => {
  if (!isEdit.value) return
  const { data } = await axios.get(`/dramas/${route.params.id}`)
  Object.assign(form.value, data)
}

const handleSubmit = async () => {
  await formRef.value.validate(async (valid) => {
    if (!valid) return
    
    loading.value = true
    
    try {
      if (isEdit.value) {
        await axios.put(`/admin/dramas/${route.params.id}`, form.value)
        ElMessage.success('Drama updated')
      } else {
        await axios.post('/admin/dramas', form.value)
        ElMessage.success('Drama created')
      }
      router.push('/dramas')
    } catch (error) {
      ElMessage.error('Operation failed')
    } finally {
      loading.value = false
    }
  })
}

onMounted(() => {
  loadCategories()
  loadDrama()
})
</script>
