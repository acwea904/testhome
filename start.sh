#!/bin/bash

# 哪吒 Agent 参数（从环境变量读取）
NEZHA_SERVER=${NEZHA_SERVER:-""}
NEZHA_CLIENT_SECRET=${NEZHA_CLIENT_SECRET:-""}
NEZHA_CLIENT_UUID=${NEZHA_CLIENT_UUID:-""}
NEZHA_TLS=${NEZHA_TLS:-"false"}
NEZHA_SCRIPT_VERSION=${NEZHA_SCRIPT_VERSION:-"main"}

# 下载并安装哪吒 Agent
download_nezha_agent() {
    echo "正在下载哪吒 Agent 安装脚本..."
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    
    # 下载安装脚本
    curl -L "https://raw.githubusercontent.com/nezhahq/scripts/${NEZHA_SCRIPT_VERSION}/agent/install.sh" \
        -o "${TEMP_DIR}/install.sh" 2>/dev/null
    
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
        echo "参数: ${INSTALL_ARGS}"
        
        # 使用 nohup 在后台运行
        cd /opt/nezha
        nohup bash "${TEMP_DIR}/install.sh" ${INSTALL_ARGS} > /tmp/nezha-agent.log 2>&1 &
        echo "哪吒 Agent 已启动（日志: /tmp/nezha-agent.log）"
    else
        echo "未配置哪吒 Agent 参数，跳过安装"
    fi
    
    # 清理临时文件
    rm -rf "${TEMP_DIR}"
}

# 检查是否配置了哪吒参数
if [ -n "${NEZHA_SERVER}" ] && { [ -n "${NEZHA_CLIENT_SECRET}" ] || [ -n "${NEZHA_CLIENT_UUID}" ]; }; then
    # 后台启动哪吒 Agent
    download_nezha_agent &
else
    echo "哪吒 Agent 参数不完整，跳过启动"
    echo "需要配置: NEZHA_SERVER 和 NEZHA_CLIENT_SECRET 或 NEZHA_CLIENT_UUID"
fi

# 启动 Next.js 应用
echo "启动 Next.js 应用..."
exec npm start
