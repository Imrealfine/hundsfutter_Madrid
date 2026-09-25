FROM node:20-alpine

RUN apk add --no-cache \
    libc6-compat \
    python3 \
    make \
    g++

RUN corepack enable && \
    corepack prepare pnpm@10.11.1 --activate

WORKDIR /server

# 先复制 workspace 配置
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/backend/package.json ./apps/backend/package.json
COPY apps/storefront/package.json ./apps/storefront/package.json

# 安装源码构建所需依赖
RUN pnpm install --frozen-lockfile

# 复制完整源码
COPY . .

# Admin build 时需要知道最终后端地址
ARG MEDUSA_BACKEND_URL=https://hundsfutter.dongxu.info
ENV MEDUSA_BACKEND_URL=${MEDUSA_BACKEND_URL}

ARG DISABLE_MEDUSA_ADMIN=false
ENV DISABLE_MEDUSA_ADMIN=${DISABLE_MEDUSA_ADMIN}

WORKDIR /server/apps/backend

# 构建正式版本
RUN pnpm build

# ==========================
# Production runtime
# ==========================

WORKDIR /server/apps/backend/.medusa/server

# 关键：在 standalone build 中重新安装自己的依赖
RUN npm install --omit=dev

ENV NODE_ENV=production
ENV PORT=9000

EXPOSE 9000

CMD ["sh", "-c", "./node_modules/.bin/medusa db:migrate && ./node_modules/.bin/medusa start --host 0.0.0.0 --port 9000"]
