FROM node:20-alpine

RUN apk add --no-cache \
    libc6-compat \
    python3 \
    make \
    g++

RUN corepack enable && \
    corepack prepare pnpm@10.11.1 --activate

WORKDIR /server

# 先复制 workspace 配置，提高 Docker 缓存命中率
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/backend/package.json ./apps/backend/package.json
COPY apps/storefront/package.json ./apps/storefront/package.json

RUN pnpm install --frozen-lockfile

# 复制全部项目
COPY . .

# Medusa Admin 在 build 时需要知道正式后端地址
ARG MEDUSA_BACKEND_URL=https://hundsfutter.dongxu.info
ENV MEDUSA_BACKEND_URL=${MEDUSA_BACKEND_URL}

ARG DISABLE_MEDUSA_ADMIN=false
ENV DISABLE_MEDUSA_ADMIN=${DISABLE_MEDUSA_ADMIN}

WORKDIR /server/apps/backend

# 创建正式 Production Build
RUN pnpm build

# Medusa 官方要求从 .medusa/server 启动生产构建
WORKDIR /server/apps/backend/.medusa/server

# 安装 production build 所需依赖
RUN pnpm install --prod --frozen-lockfile

ENV NODE_ENV=production
ENV PORT=9000

EXPOSE 9000

CMD ["sh", "-c", "pnpm medusa db:migrate && pnpm medusa start --host 0.0.0.0 --port 9000"]
