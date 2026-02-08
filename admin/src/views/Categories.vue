<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>Categories</span>
        <el-button type="primary" @click="showDialog = true">
          <el-icon><Plus /></el-icon>
          Add Category
        </el-button>
      </div>
    </template>
    
    <el-table :data="categories" v-loading="loading">
      <el-table-column prop="name_en" label="Name (EN)" />
      <el-table-column prop="name_es" label="Name (ES)" />
      <el-table-column prop="name_pt" label="Name (PT)" />
      <el-table-column prop="slug" label="Slug" />
      <el-table-column label="Active" width="80">
        <template #default="{ row }">
          <el-tag :type="row.is_active ? 'success' : 'info'">{{ row.is_active ? 'Yes' : 'No' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="Actions" width="150">
        <template #default="{ row }">
          <el-button size="small" @click="handleEdit(row)">Edit</el-button>
          <el-button size="small" type="danger" @click="handleDelete(row.id)">Delete</el-button>
        </template>
      </el-table-column>
    </el-table>
    
    <!-- Category Dialog -->
    <el-dialog v-model="showDialog" :title="editingCategory ? 'Edit Category' : 'Add Category'" width="500px">
      <el-form :model="categoryForm" label-width="100px">
        <el-form-item label="Name (EN)" required>
          <el-input v-model="categoryForm.name_en" />
        </el-form-item>
        <el-form-item label="Name (ES)">
          <el-input v-model="categoryForm.name_es" />
        </el-form-item>
        <el-form-item label="Name (PT)">
          <el-input v-model="categoryForm.name_pt" />
        </el-form-item>
        <el-form-item label="Slug" required>
          <el-input v-model="categoryForm.slug" />
        </el-form-item>
        <el-form-item label="Active">
          <el-switch v-model="categoryForm.is_active" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showDialog = false">Cancel</el-button>
        <el-button type="primary" @click="handleSave">Save</el-button>
      </template>
    </el-dialog>
  </el-card>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from '../utils/request'
import { ElMessage, ElMessageBox } from 'element-plus'

const categories = ref([])
const loading = ref(false)
const showDialog = ref(false)
const editingCategory = ref(null)

const categoryForm = ref({
  name_en: '',
  name_es: '',
  name_pt: '',
  slug: '',
  is_active: true
})

const loadCategories = async () => {
  loading.value = true
  try {
    const { data } = await axios.get('/categories')
    categories.value = data
  } finally {
    loading.value = false
  }
}

const handleEdit = (category) => {
  editingCategory.value = category
  Object.assign(categoryForm.value, category)
  showDialog.value = true
}

const handleSave = async () => {
  try {
    if (editingCategory.value) {
      await axios.put(`/admin/categories/${editingCategory.value.id}`, categoryForm.value)
      ElMessage.success('Category updated')
    } else {
      await axios.post('/admin/categories', categoryForm.value)
      ElMessage.success('Category created')
    }
    
    showDialog.value = false
    editingCategory.value = null
    loadCategories()
  } catch (error) {
    ElMessage.error('Operation failed')
  }
}

const handleDelete = async (id) => {
  try {
    await ElMessageBox.confirm('Delete this category?', 'Warning', { type: 'warning' })
    await axios.delete(`/admin/categories/${id}`)
    ElMessage.success('Category deleted')
    loadCategories()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('Failed to delete')
    }
  }
}

onMounted(() => {
  loadCategories()
})
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
