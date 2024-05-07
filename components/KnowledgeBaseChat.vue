<script setup>

import MarkdownIt from "markdown-it";
import MarkdownItAbbr from "markdown-it-abbr";
import MarkdownItAnchor from "markdown-it-anchor";
import MarkdownItFootnote from "markdown-it-footnote";
import MarkdownItHighlightjs from "markdown-it-highlightjs";
import MarkdownItSub from "markdown-it-sub";
import MarkdownItSup from "markdown-it-sup";
import MarkdownItTasklists from "markdown-it-task-lists";
import MarkdownItTOC from "markdown-it-toc-done-right";
import { fetchHeadersOllama, loadOllamaInstructions } from '@/utils/settings';
//解析markdown文本
const markdown = new MarkdownIt()
  .use(MarkdownItAbbr)
  .use(MarkdownItAnchor)
  .use(MarkdownItFootnote)
  .use(MarkdownItHighlightjs)
  .use(MarkdownItSub)
  .use(MarkdownItSup)
  .use(MarkdownItTasklists)
  .use(MarkdownItTOC);
//存指令
const instructions = ref([]);
//存选中的指令
const selectedInstruction = ref(null);
//模型
const model = ref(null);
//存聊天记录
const messages = ref([]);
//存发送按钮加载状态
const sending = ref(false);
//存输入框和发送按钮状态
const state = reactive({
  instruction: "",
  input: ""
})
//获取可见的聊天记录
const visibleMessages = computed(() => {
  return messages.value.filter((message) => message.role !== 'system');
});
//监听 model 变量的变化，清空 messages 数组
watch(model, async (newModel) => {
  messages.value = [];
})
//获取流式响应
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
    console.log("浏览器不支持流式响应.");
  }
}
//用于处理发送消息的点击事件
const onSend = async () => {
  // 如果发送按钮正在加载或输入框为空或未选择模型，则退出
  if (sending.value || !state.input?.trim() || !model.value) {
    return;
  }
  // 发送按钮加载中状态设置为 true
  sending.value = true;
  // 获取输入框的值
  const { input } = state;
  // 行数设置为 1
  rows.value = 1;
  // 等待 50 毫秒后将输入框的值清空
  setTimeout(() => {
    state.input = "";
  }, 50);
  //如果选择了指南说明，并且聊天记录中不存在系统消息，则在聊天记录的开头添加系统消息
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
  // 添加用户输入的消息到聊天记录中
  messages.value.push({
    role: "user",
    content: input
  });
  // 创建一个包含消息和模型名称的 JSON 字符串，发送到后端进行处理
  const body = JSON.stringify({
    knowledgebase: props.knowledgebase,
    model: model.value,
    messages: [...messages.value],
    stream: true,
  })
  await fetchStream('/api/models/chat', {
    method: 'POST',
    body: body,
    headers: {
      ...fetchHeadersOllama.value,
      'Content-Type': 'application/json',
    },
  });
  // 发送按钮加载中状态设置为 false
  sending.value = false;
}
// onModelSelected 函数用于处理模型选择下拉列表的选择事件
const onModelSelected = (modelName) => {
  model.value = modelName;
}
// rows 变量用于存储输入框的行数
const rows = ref(1);
// onMounted 函数用于在组件挂载到 DOM 中时执行一些初始化操作
onMounted(async () => {
  instructions.value = [await loadOllamaInstructions().map(i => {
    return {
      label: i.name,
      click: () => {
        selectedInstruction.value = i;
      }
    }
  })];
});

</script>
<template>
  <div class="flex flex-col flex-1 p-4">
    <div class="flex flex-row items-center justify-between mb-4 pb-4">
      <div class="flex flex-row" v-if="model">
        <span>选择模型</span>
        <h1 class="font-bold pl-1">{{ model }}</h1>
      </div>
      <!-- 模型选择下拉列表 -->
      <ModelsDropdown @modelSelected="onModelSelected" />
    </div>
    <div class="flex flex-row items-center justify-between mb-4 pb-4 border-b border-b-gray-200">
      <UDropdown :items="instructions" :popper="{ placement: 'bottom-start' }">
        <UButton color="white" :label="`${selectedInstruction ? selectedInstruction.name : '选择指令'}`"
          trailing-icon="i-heroicons-chevron-down-20-solid" />
      </UDropdown>
    </div>
    <div dir="ltr" class="relative overflow-y-scroll flex-1 space-y-4">
      <ul className="flex flex-1 flex-col">
        <li v-for="(message, index) in visibleMessages" :key="index">
          <div
            :class="`${message.role == 'assistant' ? 'bg-white' : 'bg-primary-50'} border border-slate-150 rounded my-4 px-3 py-2 text-sm`">
            <h3 class="font-bold">{{ message.role }}</h3>
            <div v-html="markdown.render(message.content)" />
          </div>
        </li>
      </ul>
    </div>
    <div class="mt-4">
      <UForm :state="state" @submit="onSend" @keydown.shift.enter="onSend">
        <div class="flex flex-row w-full gap-2">
          <UTextarea class="flex-1" autoresize :rows="rows" v-model="state.input" />
          <UButton type="submit" :disabled="!model" :loading="sending" class="h-fit">
            Send
          </UButton>
        </div>
      </UForm>
    </div>
  </div>
</template>

<style>
code {
  color: rgb(37 99 235);
}

.hljs {
  display: block;
  padding: 8px;
  background-color: #e5e5e5;
  margin-top: 8px;
  margin-bottom: 8px;
}
</style>
