<script setup>
import { fetchHeadersOllama, fetchHeadersThirdApi } from '@/utils/settings'

const toast = useToast()
const state = reactive({
  selectedFiles: '',
  name: '',
  embedding: '',
  description: '',
});

const validate = (state) => {
  const errors = []
  if (!state.name) errors.push({ path: 'name', message: 'Required' })
  if (!state.embedding) errors.push({ path: 'embedding', message: 'Required' })
  return errors
}

const selectedFiles = ref([]);
const onFileChange = async (e) => {
  selectedFiles.value = e.target.files;
};
const loading = ref(false);
const onSubmit = async () => {
  loading.value = true;
  const formData = new FormData();
  Array.from(selectedFiles.value).forEach((file, index) => {
    console.log(`Index ${index}`, file);
    formData.append(`file_${index}`, file);
  });

  formData.append("name", state.name);
  formData.append("description", state.description);
  formData.append("embedding", state.embedding);

  try {
    await $fetch(`/api/knowledgebases/`, {
      method: 'POST',
      body: formData,
      headers: {
        ...fetchHeadersOllama.value,
        ...fetchHeadersThirdApi.value,
      }
    });
    reset()
    refresh();
  } catch (e) {
    const msg = e.response._data?.message || e.message;
    toast.add({ color: 'red', title: 'Tips', description: msg })
  }

  loading.value = false;
}

const { data, refresh } = await useFetch('/api/knowledgebases');

const columns = [{
  key: 'id',
  label: 'ID'
}, {
  key: 'name',
  label: '知识库名称'
}, {
  key: 'files',
  label: '文件'
}, {
  key: 'description',
  label: '描述'
}, {
  key: 'embedding',
  label: '嵌入文本模式'
}, {
  key: 'actions'
}];

const knowlegeBases = computed(() => {
  return data.value.knowledgeBases.map((knowledgebase) => {
    return {
      id: knowledgebase.id,
      name: knowledgebase.name,
      files: knowledgebase.files.map((file) => file.url).join(','),
      description: knowledgebase.description,
      embedding: knowledgebase.embedding,
    }
  });
});


const actionsItems = (row) => {
  return [[{
    label: 'Delete',
    icon: 'i-heroicons-trash-20-solid',
    click: () => onDelete(row.id)
  }]]
}

const onDelete = async (id) => {
  await $fetch(`/api/knowledgebases/${id}`, {
    method: 'DELETE',
    body: { id },
  });
  refresh();
}

function reset() {
  state.name = '';
  state.embedding = '';
  state.description = '';
  state.selectedFiles = '';
}
</script>

<template>
  <div class="flex flex-row w-full">
    <div class="px-6 w-[400px]">
      <h2 class="font-bold text-xl mb-4">添加知识库</h2>
      <UForm :state="state" :validate="validate" class="space-y-4" @submit="onSubmit">
        <UFormGroup label="知识库名称" name="name" required>
          <UInput type="text" v-model="state.name" />
        </UFormGroup>

        <UFormGroup label="嵌入文本模式" name="embedding" required>
          <UInput type="text" v-model="state.embedding" />
        </UFormGroup>

        <UFormGroup label="描述" name="description">
          <UTextarea autoresize :rows="2" v-model="state.description" />
        </UFormGroup>

        <UFormGroup label="选择知识库文件" name="file">
          <UInput multiple type="file" size="sm" accept=".txt,.json,.md,.doc,.docx,.pdf" v-model="state.selectedFiles" @change="onFileChange" />
        </UFormGroup>

        <UButton type="submit" :loading="loading">
          Save
        </UButton>
      </UForm>
    </div>
    <div class="flex flex-col flex-1 px-6">
      <h2 class="font-bold text-xl mb-4">知识库</h2>
      <ClientOnly>
        <UTable :columns="columns" :rows="knowlegeBases">
          <template #name-data="{ row }">
            <ULink :to="`/knowledgebases/${row.id}`"
              class="text-blue-600 dark:text-blue-300 hover:text-blue-700 dark:hover:text-blue-200 underline">
              {{ row.name }}
            </ULink>
          </template>

          <template #actions-data="{ row }">
            <UDropdown :items="actionsItems(row)">
              <UButton color="gray" variant="ghost" icon="i-heroicons-ellipsis-horizontal-20-solid" />
            </UDropdown>
          </template>
        </UTable>
      </ClientOnly>
    </div>
  </div>
</template>
