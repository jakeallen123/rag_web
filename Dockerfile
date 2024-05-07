ARG NODE_VERSION=20.5.1

FROM node:${NODE_VERSION}-slim

RUN echo "deb http://mirrors.aliyun.com/debian/ bookworm main non-free contrib" > /etc/apt/sources.list \n    \
    && echo "deb-src http://mirrors.aliyun.com/debian/ bookworm main non-free contrib" >> /etc/apt/sources.list \n    \
    && echo "deb http://mirrors.aliyun.com/debian-security bookworm-security main" >> /etc/apt/sources.list \n    \
    && echo "deb-src http://mirrors.aliyun.com/debian-security bookworm-security main" >> /etc/apt/sources.list \n    \
    && echo "deb http://mirrors.aliyun.com/debian/ bookworm-updates main non-free contrib" >> /etc/apt/sources.list \n    \
    && echo "deb-src http://mirrors.aliyun.com/debian/ bookworm-updates main non-free contrib" >> /etc/apt/sources.list \n    \
    && echo "deb http://mirrors.aliyun.com/debian/ bookworm-backports main non-free contrib" >> /etc/apt/sources.list \n    \
    && echo "deb-src http://mirrors.aliyun.com/debian/ bookworm-backports main non-free contrib" >> /etc/apt/sources.list

RUN apt-get update
RUN apt-get install -y openssl

WORKDIR /app

COPY pnpm-lock.yaml package.json ./

RUN npm install -g pnpm

RUN pnpm i

COPY . .

RUN pnpm run prisma-generate
RUN pnpm run build

EXPOSE 3000

CMD ["node", ".output/server/index.mjs"]
