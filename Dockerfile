# =========================
# 1. Builder
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

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/backend/package.json ./apps/backend/package.json
COPY apps/storefront/package.json ./apps/storefront/package.json

RUN pnpm install --frozen-lockfile

COPY . .

# Admin 在 build 时需要知道最终公网 Backend URL
ARG MEDUSA_BACKEND_URL=https://hundsfutter.dongxu.info
ARG DISABLE_MEDUSA_ADMIN=false

ENV MEDUSA_BACKEND_URL=${MEDUSA_BACKEND_URL}
ENV DISABLE_MEDUSA_ADMIN=${DISABLE_MEDUSA_ADMIN}

WORKDIR /server/apps/backend

RUN pnpm build


# =========================
# 2. Production Runtime
# =========================
FROM node:20-alpine AS runner

RUN apk add --no-cache libc6-compat

RUN corepack enable && \
    corepack prepare pnpm@10.11.1 --activate

WORKDIR /app

# 只复制 Medusa 的 standalone production build
COPY --from=builder /server/apps/backend/.medusa/server ./

# 此时 /app 已经脱离 monorepo
RUN pnpm install --prod --frozen-lockfile

ENV NODE_ENV=production
ENV PORT=9000

EXPOSE 9000

CMD ["sh", "-c", "pnpm exec medusa db:migrate && pnpm start"]
