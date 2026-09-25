FROM node:20-alpine

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

WORKDIR /server/apps/backend

EXPOSE 9000
EXPOSE 5173

CMD ["sh", "-c", "pnpm medusa db:migrate && pnpm medusa develop --host 0.0.0.0"]
