#!/bin/bash
set -e

echo "Starting Nezha Agent and Next.js Application..."

# 检查是否启用哪吒 Agent
if [ -n "${ENABLE_NEZHA}" ] && [ "${ENABLE_NEZHA}" = "true" ]; then
    echo "Installing and starting Nezha Agent..."
    
    # 确定使用哪种认证方式 (优先使用 UUID)
    if [ -n "${NEZHA_CLIENT_UUID}" ] && [ ! -z "${NEZHA_CLIENT_UUID}" ]; then
        echo "Using UUID authentication..."
        export NZ_CLIENT_SECRET="${NEZHA_CLIENT_UUID}"
    elif [ -n "${NEZHA_CLIENT_SECRET}" ] && [ ! -z "${NEZHA_CLIENT_SECRET}" ]; then
        echo "Using Client Secret authentication..."
        export NZ_CLIENT_SECRET="${NEZHA_CLIENT_SECRET}"
    else
        echo "ERROR: No authentication method provided for Nezha Agent!"
        echo "Please set either NEZHA_CLIENT_UUID or NEZHA_CLIENT_SECRET environment variable"
        exit 1
    fi
    
    # 设置哪吒 Agent 环境变量
    export NZ_SERVER="${NEZHA_SERVER:-agent.xinxi.pp.ua:8008}"
    export NZ_TLS="${NEZHA_TLS:-false}"
    
    echo "Nezha Agent Configuration:"
    echo "  Server: ${NZ_SERVER}"
    echo "  TLS: ${NZ_TLS}"
    echo "  Authentication: ${#NZ_CLIENT_SECRET} characters"
    
    # 切换到哪吒目录并安装
    cd /opt/nezha
    
    # 检查是否已经安装过
    if [ ! -f "/opt/nezha/agent" ]; then
        echo "Installing Nezha Agent..."
        ./agent.sh install
    else
        echo "Nezha Agent already installed, reconfiguring..."
        ./agent.sh update
    fi
    
    # 启动哪吒 Agent 在后台
    echo "Starting Nezha Agent..."
    ./agent.sh start &
    
    # 等待几秒确保 Agent 启动
    sleep 3
fi

# 启动 Next.js 应用
echo "Starting Next.js application on port ${PORT}..."
exec npm start
