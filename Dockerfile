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

# 哪吒 Agent 环境变量（默认值）
ENV NEZHA_SERVER=""
ENV NEZHA_PORT=""
ENV NEZHA_TLS=""
ENV NEZHA_KEY=""  # 添加 UUID 参数
ENV NEZHA_CLIENT_SECRET=""  # 保留兼容性

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

# 下载哪吒 Agent 安装脚本
RUN curl -L https://raw.githubusercontent.com/nezhahq/scripts/main/agent/install.sh -o agent.sh \
    && chmod +x agent.sh

# 下载哪吒 Agent 二进制文件备用
RUN curl -L https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip -o nezha-agent.zip \
    && unzip -o nezha-agent.zip \
    && rm nezha-agent.zip \
    && chmod +x nezha-agent

# =========================
# Next.js 运行文件
# =========================
WORKDIR /app

COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public

# 启动脚本
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3000
CMD ["/start.sh"]
