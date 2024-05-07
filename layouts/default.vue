<script setup>
const route = useRoute()

const links = [
  [{
    label: '主页',
    icon: 'i-heroicons-home',
    to: '/'
  }, {
    label: '模型',
    icon: 'i-heroicons-rectangle-stack',
    to: '/models'
  }, {
    label: '预填指令',
    icon: 'i-heroicons-document-text',
    to: '/instructions'
  }, {
    label: 'RAG增强知识库',
    icon: 'i-heroicons-book-open',
    to: '/knowledgebases'
  }, {
    label: '聊天',
    icon: 'i-heroicons-pencil-square',
    to: '/chat'
  }, {
    label: '设置',
    icon: 'i-heroicons-cog-6-tooth',
    to: '/settings'
  }], [{
    label: '漏洞信息知识库',
    labelClass: 'text-2xl font-semibold text-primary'
  }]
]
</script>
<template>
  <div class="h-screen flex flex-col w-full">
    <UHorizontalNavigation :links="links" class="border-b border-gray-200 dark:border-gray-800" />

    <div class="p-4 flex flex-1 overflow-y-scroll justify-center">
      <slot />
    </div>
    <UNotifications />
  </div>
</template>
