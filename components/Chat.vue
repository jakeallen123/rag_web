<script setup>
import { useStorage, useMutationObserver } from '@vueuse/core'
import MarkdownIt from "markdown-it";
import MarkdownItAbbr from "markdown-it-abbr";
import MarkdownItAnchor from "markdown-it-anchor";
import MarkdownItFootnote from "markdown-it-footnote";
import MarkdownItHighlightjs from "markdown-it-highlightjs";
import MarkdownItSub from "markdown-it-sub";
import MarkdownItSup from "markdown-it-sup";
import MarkdownItTasklists from "markdown-it-task-lists";
import MarkdownItTOC from "markdown-it-toc-done-right";
import {
  fetchHeadersOllama,
  fetchHeadersThirdApi,
  loadOllamaInstructions,
} from '@/utils/settings';

// 定义 props，接收 knowledgebase 对象
const props = defineProps({
  knowledgebase: Object
});

// 创建一个 MarkdownIt 对象，用于解析 Markdown 文本
const markdown = new MarkdownIt()
  .use(MarkdownItAbbr)
  .use(MarkdownItAnchor)
  .use(MarkdownItFootnote)
  .use(MarkdownItHighlightjs)
  .use(MarkdownItSub)
  .use(MarkdownItSup)
  .use(MarkdownItTasklists)
  .use(MarkdownItTOC);

// 定义一个 instructions 数组，用于存储指令列表
const instructions = ref([]);
// 定义一个 selectedInstruction 变量，用于存储当前选择的指令
const selectedInstruction = ref(null);
// 定义一个 model 变量，用于存储当前使用的模型
const model = useStorage(`model${props.knowledgebase?.id || ''}`, null);
// 定义一个 messages 数组，用于存储对话消息
const messages = ref([]);
// 定义一个 sending 变量，用于存储发送状态
const sending = ref(false);
// 定义一个状态对象，用于存储输入框和发送按钮状态
const state = reactive({
  instruction: "",
  input: ""
})
// 定义一个可观察的 visibleMessages 变量，用于过滤系统消息
const visibleMessages = computed(() => {
  return messages.value.filter((message) => message.role !== 'system');
});
// 监听 model 变化，清空消息数组
watch(model, async (newModel) => {
  messages.value = [];
})
// 定义一个fetchStream函数，用于发送流式请求
const fetchStream = async (url, options) => {
  const response = await fetch(url, options);

  if (response.body) {
    const reader = response.body.getReader();
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = new TextDecoder().decode(value);
      chunk.split("\n\n").forEach(async (line) => {
        if (line) {
          console.log('line: ', line);
          const chatMessage = JSON.parse(line);
          const content = chatMessage?.message?.content;
          if (content) {
            if (messages.value.length > 0 && messages.value[messages.value.length - 1].role === 'assistant') {
              messages.value[messages.value.length - 1].content += content;
            } else {
              messages.value.push({ role: 'assistant', content });
            }
          }
        }
      });
    }
  } else {
    console.log("The browser doesn't support streaming responses.");
  }
}
// 定义一个 onSend 函数，用于发送消息
const onSend = async () => {
  // 如果正在发送或输入为空或没有模型，则退出
  if (sending.value || !state.input?.trim() || !model.value) {
    return;
  }
  // 发送状态设置为发送中
  sending.value = true;
  // 获取输入框的值
  const { input } = state;
  rows.value = 1;
  // 等待一段50ms后清空输入框
  setTimeout(() => {
    state.input = "";
  }, 50);
  // 如果有选择的指令，则将其添加到消息数组开头
  if (selectedInstruction.value) {
    if (messages.value.length > 0 && messages.value[0].role === 'system') {
      messages.value[0].content = selectedInstruction.value.instruction;
    } else {
      messages.value = [{
        role: "system",
        content: selectedInstruction.value.instruction
      }, ...messages.value];
    }
  }
  // 将用户输入添加到消息数组结尾
  messages.value.push({
    role: "user",
    content: input
  });
  // 创建请求体，包含知识库 ID、模型、消息数组和流式标志
  const body = JSON.stringify({
    knowledgebaseId: props.knowledgebase?.id,
    model: model.value,
    messages: [...messages.value],
    stream: true,
  })
  // 使用 fetchStream 函数发送流式请求
  await fetchStream('/api/models/chat', {
    method: 'POST',
    body: body,
    headers: {
      ...fetchHeadersOllama.value,
      ...fetchHeadersThirdApi.value,
      'Content-Type': 'application/json',
    }
  });
  // 发送状态设置为未发送
  sending.value = false;
}
// 定义一个 rows 变量，用于存储输入框的行数
const rows = ref(1);
// 在组件挂载时，加载 Ollama 的指令列表
onMounted(async () => {
  instructions.value = [(await loadOllamaInstructions()).map(i => {
    return {
      label: i.name,
      click: () => {
        selectedInstruction.value = i;
      }
    }
  })];
});

// 定义一个 messageListEl 变量，用于存储消息列表元素
const messageListEl = ref(null);
// 使用 useMutationObserver 观察消息列表元素，滚动到底部
useMutationObserver(messageListEl, () => {
  messageListEl.value.scrollTo({
    top: messageListEl.value.scrollHeight,
    behavior: 'smooth'
  });
}, { childList: true, subtree: true });

</script>

<template>
  <!-- 聊天界面 -->
  <div class="flex flex-col flex-1 p-4">
    <!-- 顶部栏 -->
    <div class="flex items-center justify-between mb-4">
      <!-- 标题和模型选择器 -->
      <div class="flex items-center">
        <span class="mr-2">选择模型:</span>
        <ModelsDropdown v-model="model" placeholder="选择一个模型" />
      </div>
      <!-- 指令选择器 -->
      <div>
        <ClientOnly>
          <UDropdown :items="instructions" :popper="{ placement: 'bottom-start' }">
            <UButton color="white" :label="`${selectedInstruction ? selectedInstruction.name : '选择指令'}`"
              trailing-icon="i-heroicons-chevron-down-20-solid" />
          </UDropdown>
        </ClientOnly>
      </div>
    </div>
    <!-- 消息列表 -->
    <div ref="messageListEl" dir="ltr" class="relative overflow-y-scroll flex-1 space-y-4">
      <!-- 列表项 -->
      <ul className="flex flex-1 flex-col">
        <li v-for="(message, index) in visibleMessages" :key="index">
          <div>
          <!-- 消息内容 -->
            :class="`${message.role == 'assistant' ? 'bg-white/10' : 'bg-primary/20'} border border-primary/20 rounded my-4 px-3 py-2 text-sm`">
            <!-- 角色标识 -->
            <h3 class="font-bold">{{ message.role }}</h3>
            <!-- Markdown 文本 -->
            <div v-html="markdown.render(message.content)" />
          </div>
        </li>
      </ul>
    </div>
    <!-- 输入框和发送按钮 -->
    <div class="mt-4">
      <ClientOnly>
        <UForm :state="state" @submit="onSend" @keydown.shift.enter="onSend">
          <div class="flex flex-row w-full gap-2">
            <UTextarea class="flex-1" autoresize :rows="rows" :disabled="!model" v-model="state.input"
              placeholder="shift + enter 发送" />
            <UButton type="submit" :disabled="!model" :loading="sending" class="h-fit">
              发送
            </UButton>
          </div>
        </UForm>
      </ClientOnly>
    </div>
  </div>
</template>

<style>
code {
  color: rgb(37 99 235);
  white-space: pre-wrap;
}

.hljs {
  display: block;
  padding: 8px;
  background-color: #e5e5e5;
  margin-top: 8px;
  margin-bottom: 8px;
}
</style>
