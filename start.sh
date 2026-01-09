#!/bin/bash
set -e

# 设置哪吒 Agent 参数
# 优先使用 NEZHA_KEY，如果没有则使用 NEZHA_CLIENT_SECRET（兼容性）
NEZHA_UUID="${NEZHA_KEY:-${NEZHA_CLIENT_SECRET}}"

# 启动哪吒 Agent（如果 UUID 已设置）
if [ -n "$NEZHA_UUID" ]; then
    echo "Starting Nezha Agent with UUID: $NEZHA_UUID"
    
    # 检查是否安装了哪吒 Agent
    if [ -f "/opt/nezha/nezha-agent" ]; then
        # 直接运行二进制文件，使用环境变量
        /opt/nezha/nezha-agent \
            -s "${NEZHA_SERVER}" \
            -p "${NEZHA_PORT}" \
            -k "${NEZHA_UUID}" \
            --tls="${NEZHA_TLS}" \
            > /var/log/nezha-agent.log 2>&1 &
    else
        # 使用安装脚本
        cd /opt/nezha
        env NEZHA_SERVER="${NEZHA_SERVER}" \
            NEZHA_KEY="${NEZHA_UUID}" \
            NEZHA_PORT="${NEZHA_PORT}" \
            NEZHA_TLS="${NEZHA_TLS}" \
            ./agent.sh install
    fi
else
    echo "Nezha Agent UUID not set, skipping agent startup"
fi

# 启动 Next.js 应用
echo "Starting Next.js application"
exec npm run start
