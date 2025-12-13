#!/bin/bash
# llama.cpp RISC-V64 交叉编译脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

# 设置环境变量
export OHOS_SDK_ROOT="$SOURCE_ROOT/prebuilts/ohos-sdk/linux/12"
export OHOS_CLANG_ROOT="$SOURCE_ROOT/prebuilts/clang/ohos/linux-x86_64/llvm"
export PATH="$SOURCE_ROOT/prebuilts/cmake/linux-x86/bin:$PATH"

echo "=========================================="
echo "llama.cpp RISC-V64 交叉编译"
echo "=========================================="
echo "OHOS_SDK_ROOT: $OHOS_SDK_ROOT"
echo "OHOS_CLANG_ROOT: $OHOS_CLANG_ROOT"

# 检查工具链
if [ ! -f "$OHOS_CLANG_ROOT/bin/clang" ]; then
    echo "错误: 找不到clang编译器"
    exit 1
fi

cd "$SCRIPT_DIR"

# 创建构建目录
rm -rf build_riscv64
mkdir -p build_riscv64
cd build_riscv64

# CMake配置
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE="../ohos_riscv64.cmake" \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_NATIVE=OFF \
    -DGGML_CPU_ARM_ARCH="" \
    -DGGML_CPU_RISCV_MARCH="rv64gcv" \
    -DGGML_RVV=OFF \
    -DGGML_OPENMP=OFF \
    -DGGML_BLAS=OFF \
    -DGGML_CUDA=OFF \
    -DGGML_METAL=OFF \
    -DGGML_VULKAN=OFF \
    -DLLAMA_CURL=OFF \
    -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_EXAMPLES=OFF \
    -DLLAMA_BUILD_SERVER=OFF \
    -DBUILD_SHARED_LIBS=ON

# 编译
cmake --build . -j$(nproc)

echo ""
echo "=========================================="
echo "编译完成！"
echo "输出文件:"
find . -name "*.so" -type f
echo "=========================================="
