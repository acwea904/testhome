# =========================
# 1️⃣ Build 阶段
# =========================
FROM node:18 AS builder

WORKDIR /app

# 复制依赖文件
COPY package.json package-lock.json* yarn.lock* pnpm-lock.yaml* ./

# 安装依赖
RUN if [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
    elif [ -f pnpm-lock.yaml ]; then corepack enable && pnpm install --frozen-lockfile; \
    else npm ci; \
    fi

# 复制源码
COPY . .

# 构建 Next.js
RUN npm run build

# =========================
# 2️⃣ 运行阶段
# =========================
FROM node:18-slim

ENV NODE_ENV=production
ENV PORT=3000

# 哪吒 Agent 参数 (可在运行容器时通过环境变量覆盖)
ENV NEZHA_SERVER=agent.xinxi.pp.ua:8008
ENV NEZHA_TLS=false
ENV NEZHA_CLIENT_SECRET=1FyZCXk9XGSarBQrCVE8WjyzXTfJFqH4
# 使用 UUID 替代 client_secret (二选一)
ENV NEZHA_CLIENT_UUID=
# 哪吒 Agent 安装脚本版本
ENV NEZHA_SCRIPT_VERSION=main

# 安装哪吒 Agent 依赖
RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    bash \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# =========================
# 哪吒 Agent 安装
# =========================
WORKDIR /opt/nezha

# 复制启动脚本
COPY start.sh /start.sh
RUN chmod +x /start.sh

# 下载哪吒 Agent 安装脚本
RUN curl -L "https://raw.githubusercontent.com/nezhahq/scripts/${NEZHA_SCRIPT_VERSION}/agent/install.sh" -o agent.sh \
    && chmod +x agent.sh

# =========================
# Next.js 运行文件
# =========================
WORKDIR /app

COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public

EXPOSE 3000
CMD ["/start.sh"]
