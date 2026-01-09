#!/bin/bash

# 哪吒 Agent 参数（从环境变量读取）
NEZHA_SERVER=${NEZHA_SERVER:-""}
NEZHA_CLIENT_SECRET=${NEZHA_CLIENT_SECRET:-""}
NEZHA_CLIENT_UUID=${NEZHA_CLIENT_UUID:-""}
NEZHA_TLS=${NEZHA_TLS:-"false"}
NEZHA_SCRIPT_VERSION=${NEZHA_SCRIPT_VERSION:-"main"}

# 设置时区（重要！）
export TZ=Asia/Shanghai

echo "=== 环境变量检查 ==="
echo "NEZHA_SERVER: $NEZHA_SERVER"
echo "NEZHA_TLS: $NEZHA_TLS"
echo "NEZHA_SCRIPT_VERSION: $NEZHA_SCRIPT_VERSION"
echo "当前时区: $(date)"
echo "===================="

# 检查哪吒参数
if [ -z "$NEZHA_SERVER" ]; then
    echo "错误：NEZHA_SERVER 未设置"
    exit 1
fi

if [ -z "$NEZHA_CLIENT_SECRET" ] && [ -z "$NEZHA_CLIENT_UUID" ]; then
    echo "错误：NEZHA_CLIENT_SECRET 和 NEZHA_CLIENT_UUID 都未设置"
    exit 1
fi

# 下载并安装哪吒 Agent
download_nezha_agent() {
    echo "正在下载哪吒 Agent 安装脚本..."
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    
    # 下载安装脚本
    curl -L "https://raw.githubusercontent.com/nezhahq/scripts/${NEZHA_SCRIPT_VERSION}/agent/install.sh" \
        -o "${TEMP_DIR}/install.sh"
    
    if [ $? -ne 0 ]; then
        echo "错误：下载哪吒 Agent 安装脚本失败"
        return 1
    fi
    
    chmod +x "${TEMP_DIR}/install.sh"
    
    # 构建安装参数
    INSTALL_ARGS=""
    if [ -n "${NEZHA_SERVER}" ]; then
        INSTALL_ARGS="${INSTALL_ARGS} -s ${NEZHA_SERVER}"
    fi
    
    if [ -n "${NEZHA_CLIENT_SECRET}" ]; then
        INSTALL_ARGS="${INSTALL_ARGS} -p ${NEZHA_CLIENT_SECRET}"
    elif [ -n "${NEZHA_CLIENT_UUID}" ]; then
        INSTALL_ARGS="${INSTALL_ARGS} -u ${NEZHA_CLIENT_UUID}"
    fi
    
    if [ "${NEZHA_TLS}" = "true" ]; then
        INSTALL_ARGS="${INSTALL_ARGS} --tls"
    fi
    
    # 安装哪吒 Agent
    if [ -n "${INSTALL_ARGS}" ]; then
        echo "正在安装哪吒 Agent..."
        echo "安装命令: bash ${TEMP_DIR}/install.sh ${INSTALL_ARGS}"
        
        # 安装哪吒 Agent
        cd /opt/nezha
        if bash "${TEMP_DIR}/install.sh" ${INSTALL_ARGS}; then
            echo "哪吒 Agent 安装成功"
        else
            echo "哪吒 Agent 安装失败"
        fi
    else
        echo "未配置哪吒 Agent 参数，跳过安装"
    fi
    
    # 清理临时文件
    rm -rf "${TEMP_DIR}"
}

# 启动哪吒 Agent 服务
start_nezha_agent() {
    echo "正在启动哪吒 Agent 服务..."
    
    # 检查哪吒 Agent 是否已安装
    if [ ! -f "/opt/nezha/nezha-agent" ]; then
        echo "错误：哪吒 Agent 未找到，请先安装"
        return 1
    fi
    
    # 启动哪吒 Agent
    nohup /opt/nezha/nezha-agent >> /tmp/nezha-agent.log 2>&1 &
    
    # 检查是否启动成功
    sleep 3
    if pgrep -x "nezha-agent" > /dev/null; then
        echo "哪吒 Agent 已成功启动（PID: $(pgrep -x 'nezha-agent')）"
        echo "查看日志: tail -f /tmp/nezha-agent.log"
    else
        echo "哪吒 Agent 启动失败"
        echo "查看错误日志:"
        cat /tmp/nezha-agent.log || true
    fi
}

# 检查网络连接
check_network() {
    echo "=== 网络连接检查 ==="
    
    # 提取服务器地址和端口
    IFS=':' read -r SERVER_HOST SERVER_PORT <<< "$NEZHA_SERVER"
    
    if [ -z "$SERVER_PORT" ]; then
        SERVER_PORT=80
        if [ "$NEZHA_TLS" = "true" ]; then
            SERVER_PORT=443
        fi
    fi
    
    echo "测试连接到 $SERVER_HOST:$SERVER_PORT ..."
    
    # 使用 nc 测试连接
    if command -v nc > /dev/null 2>&1; then
        if nc -z -w 5 "$SERVER_HOST" "$SERVER_PORT"; then
            echo "✅ 可以连接到哪吒服务器"
        else
            echo "❌ 无法连接到哪吒服务器"
        fi
    else
        echo "⚠️  nc 命令未安装，跳过网络测试"
    fi
    
    echo "===================="
}

# 主程序
main() {
    # 检查网络
    check_network
    
    # 安装哪吒 Agent
    download_nezha_agent
    
    # 启动哪吒 Agent 服务
    start_nezha_agent
    
    # 启动 Next.js 应用
    echo "启动 Next.js 应用..."
    echo "监听端口: ${PORT:-3000}"
    
    # 检查端口占用
    if command -v lsof > /dev/null 2>&1; then
        if lsof -i :${PORT:-3000} > /dev/null 2>&1; then
            echo "端口 ${PORT:-3000} 已被占用"
        else
            echo "端口 ${PORT:-3000} 可用"
        fi
    fi
    
    # 启动 Next.js
    exec npm start
}

# 运行主程序
main
