#!/bin/bash
#
# 编译 llama NAPI wrapper for RISC-V64
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# 工具链路径
OHOS_SDK_ROOT="$SOURCE_ROOT/prebuilts/ohos-sdk/linux/12"
OHOS_CLANG_ROOT="$SOURCE_ROOT/prebuilts/clang/ohos/linux-x86_64/llvm"
SYSROOT="$OHOS_SDK_ROOT/native/sysroot"

# 编译器
CC="$OHOS_CLANG_ROOT/bin/clang"
CXX="$OHOS_CLANG_ROOT/bin/clang++"

# 目标架构
TARGET="riscv64-linux-ohos"

# 源文件和输出
SRC="$SCRIPT_DIR/product/phone/src/main/cpp/llama_napi.cpp"
OUT_DIR="$SCRIPT_DIR/product/phone/libs/riscv64"
OUT="$OUT_DIR/libllama_napi.so"

# llama.cpp 头文件和库
LLAMA_INCLUDE="$SCRIPT_DIR/llama_cpp/include"
GGML_INCLUDE="$SCRIPT_DIR/llama_cpp/ggml/include"
# 使用 src/main/libs 下的库（不带版本号）
LLAMA_LIB="$SCRIPT_DIR/product/phone/src/main/libs/riscv64"

echo "=========================================="
echo "编译 llama NAPI wrapper (RISC-V64)"
echo "=========================================="
echo "源文件: $SRC"
echo "输出: $OUT"
echo ""

# 检查工具链
if [ ! -f "$CXX" ]; then
    echo "错误: 找不到编译器 $CXX"
    exit 1
fi

# 检查源文件
if [ ! -f "$SRC" ]; then
    echo "错误: 找不到源文件 $SRC"
    exit 1
fi

# 创建输出目录
mkdir -p "$OUT_DIR"

# 编译
echo ">>> 编译中..."
$CXX \
    --target=$TARGET \
    --sysroot="$SYSROOT" \
    -fPIC \
    -shared \
    -std=c++17 \
    -O2 \
    -I"$LLAMA_INCLUDE" \
    -I"$GGML_INCLUDE" \
    -I"$SYSROOT/usr/include" \
    -I"$OHOS_SDK_ROOT/native/sysroot/usr/include/napi" \
    -L"$LLAMA_LIB" \
    -L"$SYSROOT/usr/lib/$TARGET" \
    -lllama \
    -lggml \
    -lggml-base \
    -lggml-cpu \
    -lace_napi.z \
    -lhilog_ndk.z \
    -Wl,-rpath,\$ORIGIN \
    -o "$OUT" \
    "$SRC"

echo ""
echo "=========================================="
echo "编译完成!"
echo "输出: $OUT"
ls -la "$OUT"
echo "=========================================="
