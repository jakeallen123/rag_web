# RAG网安知识数据库

### 支持的向量数据库

支持 2 种向量数据库：Milvus 和 Chroma。

请参阅 `.env.example` 文件，了解如何使用向量数据库配置。

```
# 支持的值：chroma，milvus
VECTOR_STORE=chroma
CHROMADB_URL=http://localhost:8000
MILVUS_URL=http://localhost:19530
```

默认情况下，使用 Chroma。如果您想使用 Milvus，请将 `VECTOR_STORE` 设置为 `milvus`，并指定相应的 URL。它在开发服务器和 Docker 容器中都可用。

### 使用 Nuxt 3 开发服务器

如果您想在最新的代码库中运行，并且可以实时应用更改，clone 该存储库，并按照以下步骤进行：

1. 安装 Ollama 服务器

   您需要运行 Ollama 服务器。按照 [Ollama](https://github.com/ollama/ollama) 的安装指南进行安装。默认情况下，它运行在 http://localhost:11434。
2. 安装 Chroma

   请参阅 [https://docs.trychroma.com/getting-started](https://docs.trychroma.com/getting-started) 获取 Chroma 安装指南。

   我们建议在 Docker 容器中运行：

   ```bash
   # https://hub.docker.com/r/chromadb/chroma/tags

   docker pull chromadb/chroma
   docker run -d -p 8000:8000 chromadb/chroma
   ```

   现在，ChromaDB 正在运行于 http://localhost:8000
3. 设置

   现在，我们可以完成必要的设置，以便运行项目。

   3.1 复制 `.env.example` 文件到 `.env` 文件：

   ```bash
   cp .env.example .env
   ```

   3.2 确保安装依赖项：

   ```bash
   pnpm install
   ```

   3.3 运行迁移命令以创建数据库表：

   ```bash
   pnpm prisma-migrate
   ```
4. 启动开发服务器

   > 确保 __[Ollama Server](#ollama-server)__  服务器和 __[ChromaDB](#install-chromadb-and-startup)__  都正在运行。
   >

   启动开发服务器在 `http://localhost:3000`：

   ```bash
   pnpm dev
   ```

### 使用 Docker

构建本地镜像的方法：

1. 写好dockerfile
2. build 相应文件

```shell
$ docker build -t jakeallen/rag_web:v2 .
```

唯一需要的是复制一份 [docker-compose.yaml](./docker-compose.yaml)。请下载它，并执行以下命令以启动项目：

```shell
$ docker compose up
```

由于项目 在 Docker 容器中运行，您需要将 Ollama 服务器设置为 `http://host.docker.internal:11434`，假设您的 Ollama 服务器在本地运行默认端口。

如果这是您第一次在 Docker 中启动，请初始化 SQLite 数据库：

```shell
$ docker compose exec chatollama npx prisma migrate dev
```

#### 使用知识库的提前准备

使用知识库时，我们需要一个有效的嵌入模型。在这里可以是 Ollama 下载的模型或来自第三方服务提供商，例如 OpenAI。

**Ollama 管理嵌入模型**

我们推荐使用 `nomic-embed-text` 模型。

可以在 Models 页面 [http://localhost:3000/models](http://localhost:3000/models) 或使用 CLI 进行下载：

```shell
# 在 docker-compose.yaml 文件夹中

$ docker compose exec ollama ollama pull nomic-embed-text:latest
```

#### Docker 容器数据存储

有两个类型的数据存储：向量数据和关系数据。详细信息请参阅 [docker-compose.yaml](./docker-compose.yaml)。

##### 向量数据

使用 `docker-compose.yaml`，会在同一 Docker 容器中运行 Chroma 数据库。数据将被 保存在 Docker 卷中。

##### 关系数据

关系数据，包括知识库记录及其关联文件，存储在 SQLite 数据库文件中，保存在 `~/.chatollama/chatollama.sqlite`。

1. 安装最新依赖项
   - `pnpm install`
2. Prisma 迁移
   - `pnpm prisma-migrate`
