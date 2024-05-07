<script setup>
import { computed, ref } from 'vue';
import { fetchHeadersOllama } from '@/utils/settings'

const emit = defineEmits(["modelChanged"])

// 1. 展示所有模型的信息
const models = ref([]);
const modelRows = computed(() => {
  return models.value.map((model) => {
    return {
      name: model.name,
      size: model.size,
      family: model.details?.family,
      format: model.details?.format,
      parameter_size: model.details?.parameter_size,
      quantization_level: model.details?.quantization_level
    }
  });
});
const columns = [{
  key: 'name',
  label: '名称'
}, {
  key: 'size',
  label: '大小'
}, {
  key: 'family',
  label: '分类'
}, {
  key: 'format',
  label: '格式'
}, {
  key: 'parameter_size',
  label: '参数大小'
},
{
  key: 'quantization_level',
  label: '量化级别'
}];

// 2. 加载模型
const loadModels = async () => {
  const response = await $fetch('/api/models/', {
    headers: fetchHeadersOllama.value
  });
  models.value = response.models;
};
// 3. 删除某个模型
const selectedRows = ref([]);
const select = (row) => {
  const index = selectedRows.value.findIndex((item) => item.name === row.name)
  if (index === -1) {
    selectedRows.value.push(row)
  } else {
    selectedRows.value.splice(index, 1)
  }
};

const actions = [
  [{
    key: 'delete',
    label: '删除',
    icon: 'i-heroicons-trash-20-solid',
    click: async () => {
      isOpen.value = true;
    }
  }]
];
// 4. 管理模型的选择和操作
const selectedModelName = ref(null);

// loadModels().then(() => {
//  selectedModelName.value = models.value[0]?.name;
//  onModelChange();
//});

const modelOptions = computed(() => {
  return models.value.map((model) => model.name);
});

const onModelChange = () => {
  emit("modelChanged", selectedModelName.value);
};
// 5. 与后端交互
const onModelDownloaded = () => {
  loadModels();
};

// Model
const isOpen = ref(false);
const onDeleteModel = async () => {
  resetModal();
  selectedRows.value.forEach(async ({ name }) => {
    const status = await $fetch(`/api/models/`, {
      method: 'DELETE',
      body: {
        model: name
      },
      headers: fetchHeadersOllama.value
    });

    if (status?.status === 'success') {
      models.value = models.value.filter((m) => m.name !== name);
    }
  });
};

const onCancel = () => {
  resetModal();
};

const resetModal = () => {
  isOpen.value = false;
};

onMounted(() => {
  loadModels();
});
</script>

<template>
  <div>
    <!-- 1. 展示所有模型的信息 -->
    <div class="my-8">
      <Download @modelDownloaded="onModelDownloaded" />
    </div>
    <UDropdown v-if="selectedRows.length > 0" :items="actions" :ui="{ width: 'w-36' }">
      <UButton icon="i-heroicons-chevron-down" trailing color="gray" size="xs">
        操作
      </UButton>
    </UDropdown>

    <ClientOnly>
      <UTable :columns="columns" :rows="modelRows" @select="select" v-model="selectedRows">
        <!-- 2. 管理模型的选择和操作 -->
        <template #actions-data="{ row }">
          <UDropdown :items="items(row)">
            <UButton color="gray" variant="ghost" icon="i-heroicons-ellipsis-horizontal-20-solid" />
          </UDropdown>
        </template>
      </UTable>
    </ClientOnly>
    <!-- 3. 删除某个模型 -->
    <UModal v-model="isOpen">
      <UCard :ui="{ ring: '', divide: 'divide-y divide-gray-100 dark:divide-gray-800' }">
        <template #header>
          <span class="font-bold text-lg">警告</span>
        </template>

        <div>
          <p class="mb-4">您确定要删除以下模型吗？{{ selectedRows.length > 1 ? 's' : '' }}?</p>
          <ul>
            <li class="font-bold" v-for="row in selectedRows" :key="row.name">{{ row.name }}</li>
          </ul>
        </div>

        <template #footer>
          <div class="flex flex-row gap-4">
            <UButton class="w-[80px] justify-center" color="primary" variant="solid" @click="onDeleteModel">Ok</UButton>
            <UButton class="w-[80px] justify-center" color="white" variant="solid" @click="onCancel">Cancel</UButton>
          </div>
        </template>
      </UCard>
    </UModal>
  </div>
</template>
