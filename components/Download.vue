<script setup>
import { fetchHeadersOllama } from '@/utils/settings'
//发送事件
const emit = defineEmits(["modelDownloaded"])
//示通知消息
const toast = useToast()
//下载状态和进度信息
const state = reactive({
  modelName: undefined
});
//下载是否在进行中和存储下载进度
const downloading = ref(false);
const progresses = ref([]);

//发送流式 HTTP 请求
const fetchStream = async (url, options) => {
  const response = await fetch(url, options);

  if (response.body) {
    const reader = response.body.getReader();
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = new TextDecoder().decode(value);
      chunk.split("\n\n").forEach((line) => {
        if (line) {
          const progress = JSON.parse(line);

          if (progress.error) {
            throw new Error(progress.error);
          }

          const { total, completed = 0 } = progress;
          if (total && completed) {
            progress.percentage = `${parseInt((completed / total) * 100)}%`;
          }

          const existing = progresses.value.find((p) => p.status === progress.status);
          if (existing) {
            Object.assign(existing, progress);
          } else {
            progresses.value.push(progress);
          }
        }
      });
    }
  } else {
    console.log("The browser doesn't support streaming responses.");
  }
}
//下载模型
const onDownload = async () => {
  downloading.value = true;
  progresses.value = [];
  const { modelName } = state;
  //api下载模型
  try {
    await fetchStream('/api/models/pull', {
      method: 'POST',
      body: JSON.stringify({
        model: modelName,
        stream: true,
      }),
      headers: {
        ...fetchHeadersOllama.value,
        'Content-Type': 'application/json',
      },
    });
    //下载完成
    emit("modelDownloaded", modelName);
  } catch (error) {
    //下载失败错误信息
    progresses.value = [];
    toast.add({ color: 'red', title: "下载模型失败", description: error.message});
  }
  //下载结束，停止下载
  downloading.value = false;
};
</script>

<template>
  <!-- UForm 组件用于显示表单，UInput 组件用于输入模型名称，UButton 组件用于开始下载 -->
  <UForm :state="state" @submit="onDownload">
    <div class="flex flex-row w-full gap-2">
      <!-- UInput 组件用于输入模型名称 -->
      <UInput class="flex-1" size="lg" v-model="state.modelName" placeholder="下载模型" required/>
      <!-- UButton 组件用于开始下载 -->
      <UButton type="submit" :loading="downloading">
        下载
      </UButton>
    </div>
    <div class="text-sm text-gray-500 mt-4 mx-2">
      <!--从ollama中找模型-->
      模型参考下载链接地址：
      <a href="https://ollama.com/library" target="_blank" class="text-blue-500 underline">https://ollama.com/library</a>
    </div>
    <!-- 显示下载进度，如果有进度，则使用 UProgress 组件，否则显示状态信息 -->
    <ul class="flex flex-col gap-2 mt-4 px-3.5 py-2.5 bg-gray-100" v-if="progresses.length > 0">
      <li v-for="(progress, index) in progresses" :key="index">
        <!-- 使用 UProgress 组件显示下载进度 -->
        <UProgress :value="parseInt(progress.percentage)" indicator v-if="progress.percentage">
          <template #indicator="{ percent }">
            <!-- 显示下载状态和进度百分比 -->
            <div class="font-light text-xs text-gray-700">
              <span>{{ progress.status }}</span>
              <span class="float-right">{{ `${parseInt(percent)}%` }}</span>
            </div>
          </template>
        </UProgress>
        <!-- 如果没有进度，则显示状态信息 -->
        <span class="font-light text-xs text-gray-700" v-else>{{ progress.status }}</span>
      </li>
    </ul>
  </UForm>
</template>
