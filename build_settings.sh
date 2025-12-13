#!/bin/bash
#
# OpenHarmony Settings应用独立编译脚本
# 用于在不整编系统的情况下单独编译Settings HAP
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# SDK路径
OHOS_SDK="$SOURCE_ROOT/prebuilts/ohos-sdk/linux/12"
ETS_SDK="$OHOS_SDK/ets"
TOOLCHAINS="$OHOS_SDK/toolchains"

# Node.js（使用系统的或SDK里的）
if [ -x "$SOURCE_ROOT/prebuilts/build-tools/common/nodejs/node-v14.21.1-linux-x64/bin/node" ]; then
    NODE_HOME="$SOURCE_ROOT/prebuilts/build-tools/common/nodejs/node-v14.21.1-linux-x64"
    export PATH="$NODE_HOME/bin:$PATH"
fi

# hvigor依赖
HVIGOR_HOME="$HOME/.hvigor"

echo "=========================================="
echo "OpenHarmony Settings 应用编译"
echo "=========================================="
echo "项目目录: $SCRIPT_DIR"
echo "SDK路径: $OHOS_SDK"
echo "Node版本: $(node --version 2>/dev/null || echo '未找到')"
echo ""

# 检查SDK
if [ ! -d "$ETS_SDK" ]; then
    echo "错误: ETS SDK不存在: $ETS_SDK"
    echo "请确保已下载OpenHarmony SDK"
    exit 1
fi

cd "$SCRIPT_DIR"

# 方式1: 使用hvigorw（项目自带的wrapper）
build_with_hvigorw() {
    echo ">>> 使用hvigorw编译..."

    # 检查hvigorw
    if [ ! -f "./hvigorw" ]; then
        echo "错误: hvigorw不存在"
        return 1
    fi

    chmod +x ./hvigorw

    # 设置环境变量
    export OHOS_SDK_HOME="$SOURCE_ROOT/prebuilts/ohos-sdk/linux"
    export HOS_SDK_HOME="$OHOS_SDK"

    # 安装依赖并编译
    ./hvigorw --sync
    ./hvigorw assembleHap --mode module -p product=default -p module=phone
}

# 方式2: 直接使用hvigor（如果全局安装了）
build_with_global_hvigor() {
    echo ">>> 使用全局hvigor编译..."

    if ! command -v hvigor &> /dev/null; then
        echo "全局hvigor未安装，尝试安装..."
        npm install -g @ohos/hvigor-ohos-plugin@3.0.9
    fi

    hvigor assembleHap --mode module -p product=default -p module=phone
}

# 方式3: 使用系统整编的方式单独编译这个组件
build_with_hb() {
    echo ">>> 使用hb编译（仅NAPI部分）..."

    cd "$SOURCE_ROOT"

    # 确保hb已安装
    if ! command -v hb &> /dev/null; then
        echo "安装hb工具..."
        pip3 install -e build/hb
    fi

    # 单独编译settings组件
    hb build -p settings --fast-rebuild
}

# 主逻辑
case "${1:-hvigorw}" in
    hvigorw)
        build_with_hvigorw
        ;;
    hvigor)
        build_with_global_hvigor
        ;;
    hb)
        build_with_hb
        ;;
    clean)
        echo ">>> 清理编译产物..."
        rm -rf ./build ./node_modules ./.preview ./oh-package-lock.json5
        rm -rf ./product/phone/build ./product/phone/node_modules
        rm -rf ./common/*/build ./common/*/node_modules
        echo "清理完成"
        ;;
    *)
        echo "用法: $0 [hvigorw|hvigor|hb|clean]"
        echo ""
        echo "  hvigorw  - 使用项目自带的hvigorw编译HAP（默认）"
        echo "  hvigor   - 使用全局安装的hvigor编译"
        echo "  hb       - 使用系统构建工具编译NAPI部分"
        echo "  clean    - 清理编译产物"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
if [ -d "./product/phone/build" ]; then
    echo "编译产物位置:"
    find ./product/phone/build -name "*.hap" 2>/dev/null || echo "未找到HAP文件"
fi
echo "=========================================="
