# =========================
# Builder
# =========================
FROM node:20-alpine AS builder

RUN apk add --no-cache \
    libc6-compat \
    python3 \
    make \
    g++

RUN corepack enable && \
    corepack prepare pnpm@10.11.1 --activate

WORKDIR /server

# 先复制 workspace 依赖描述文件，利用 Docker cache
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY .npmrc ./

COPY apps/backend/package.json ./apps/backend/package.json
COPY apps/storefront/package.json ./apps/storefront/package.json

# 安装整个 monorepo 的依赖
RUN pnpm install --frozen-lockfile

# 再复制源码
COPY . .

# Admin build 时需要知道正式 Backend 地址
ARG MEDUSA_BACKEND_URL=https://hundsfutter.dongxu.info
ENV MEDUSA_BACKEND_URL=${MEDUSA_BACKEND_URL}

ARG DISABLE_MEDUSA_ADMIN=false
ENV DISABLE_MEDUSA_ADMIN=${DISABLE_MEDUSA_ADMIN}

WORKDIR /server/apps/backend

# 构建 Medusa production server + Admin
RUN pnpm build


# =========================
# Production Runtime
# =========================
FROM node:20-alpine AS runner

RUN apk add --no-cache \
    libc6-compat \
    python3 \
    make \
    g++

RUN corepack enable && \
    corepack prepare pnpm@10.11.1 --activate

WORKDIR /app

# 只复制 Medusa 独立 production build
COPY --from=builder /server/apps/backend/.medusa/server ./

# 把 pnpm 配置也带进独立运行目录
COPY --from=builder /server/.npmrc ./.npmrc

# 这里不要 frozen，因为 .medusa/server 是 build 生成的独立项目
RUN pnpm install --prod --no-frozen-lockfile

ENV NODE_ENV=production
ENV PORT=9000

EXPOSE 9000

# 先 migration，再启动 production server
CMD ["sh", "-c", "pnpm exec medusa db:migrate && pnpm start"]
