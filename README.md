# OpenHarmony Settings + AI Agent

基于OpenHarmony 5.0的系统设置应用，集成了本地AI助手功能（llama.cpp + Qwen）。

> 详细开发记录见 [开发历史.md](开发历史.md)

## 特性

- 完全本地运行，无需联网，保护用户隐私
- 支持多轮对话（保留最近3轮历史）
- 异步推理，不阻塞UI

## 前置要求

- OpenHarmony SDK 12（含目标架构工具链）
- CMake 3.14+
- patchelf
- hdc 命令行工具

## 支持的架构

| 架构 | 目标设备 | 编译脚本 | 库目录 |
|------|----------|----------|--------|
| RISC-V64 | Spacemit X60 | `llama_cpp/build_riscv64.sh` | `product/phone/libs/riscv64/` |
| ARM64 | P7885 等 | `llama_cpp/build_arm64.sh` | `product/phone/libs/arm64-v8a/` |

当前仓库预编译的是 RISC-V64 版本。ARM64 需要重新编译（见下方说明）。

## 快速开始（使用预编译库）

如果只是想快速体验，可以直接使用仓库中预编译的 .so 库。

### 1. 克隆仓库
```bash
git clone git@github.com:lmxxf/ai-agent-on-openharmony5.0-riscv.git
cd ai-agent-on-openharmony5.0-riscv
```

### 2. 配置SDK路径
```bash
# 创建local.properties，指向OpenHarmony SDK
# SDK路径固定为：OpenHarmony工程路径/prebuilts/ohos-sdk/linux
# 例如 ~/muse-paper/source/prebuilts/ohos-sdk/linux
echo "sdk.dir=/你的OpenHarmony工程路径/prebuilts/ohos-sdk/linux" > local.properties
```

### 3. 编译Settings应用
```bash
./build_settings.sh
```

产物位置：`product/phone/build/default/outputs/default/phone-default-signed.hap`

### 4. 安装到设备
```bash
hdc install product/phone/build/default/outputs/default/phone-default-signed.hap
```

### 5. 下载并上传模型
```bash
# 下载 Qwen2.5-0.5B 量化模型（约 470MB）
wget https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf -O qwen2.5-0.5b-q4.gguf

# 上传到设备
hdc file send qwen2.5-0.5b-q4.gguf /data/app/el2/100/base/com.ohos.settings/files/
```

### 6. 使用AI助手
打开设置应用 → 点击"AI助手"入口 → 等待模型加载完成后即可对话

---

## 从源码编译（完整流程）

如果需要修改 llama.cpp 或 NAPI 封装，按以下步骤从源码编译。

### 1. 下载 llama.cpp 源码

```bash
# 克隆 llama.cpp 到 llama_cpp 目录
git clone --depth 1 https://github.com/ggerganov/llama.cpp.git llama_cpp_src

# 复制需要的文件到 llama_cpp/
mkdir -p llama_cpp
cp -r llama_cpp_src/{src,include,ggml,common,cmake,vendor,tools,CMakeLists.txt,LICENSE} llama_cpp/

# 清理临时目录
rm -rf llama_cpp_src
```

### 2. 编译 llama.cpp (RISC-V64)

```bash
cd llama_cpp
./build_riscv64.sh
```

编译产物在 `llama_cpp/build_riscv64/bin/`，包括：
- `libllama.so.0`
- `libggml.so.0`
- `libggml-base.so.0`
- `libggml-cpu.so.0`

### 3. 处理 .so 库（去除版本号）

```bash
cd llama_cpp/build_riscv64/bin

# 复制并重命名（去掉版本号）
cp libllama.so.0.0.* ../../../product/phone/src/main/libs/riscv64/libllama.so
cp libggml.so.0.* ../../../product/phone/src/main/libs/riscv64/libggml.so
cp libggml-base.so.0.* ../../../product/phone/src/main/libs/riscv64/libggml-base.so
cp libggml-cpu.so.0.* ../../../product/phone/src/main/libs/riscv64/libggml-cpu.so

cd ../../../product/phone/src/main/libs/riscv64

# 修复 SONAME（patchelf）
patchelf --set-soname libllama.so libllama.so
patchelf --set-soname libggml.so libggml.so
patchelf --set-soname libggml-base.so libggml-base.so
patchelf --set-soname libggml-cpu.so libggml-cpu.so

# 修复依赖名
patchelf --replace-needed libggml.so.0 libggml.so libllama.so
patchelf --replace-needed libggml-base.so.0 libggml-base.so libllama.so
patchelf --replace-needed libggml-cpu.so.0 libggml-cpu.so libllama.so
patchelf --replace-needed libggml-base.so.0 libggml-base.so libggml.so
patchelf --replace-needed libggml-base.so.0 libggml-base.so libggml-cpu.so

# 设置 RUNPATH
patchelf --set-rpath '$ORIGIN' libllama.so
patchelf --set-rpath '$ORIGIN' libggml.so
patchelf --set-rpath '$ORIGIN' libggml-base.so
patchelf --set-rpath '$ORIGIN' libggml-cpu.so
```

### 4. 编译 NAPI wrapper

```bash
cd /path/to/settings
./build_napi.sh

# 修复 NAPI .so 的依赖
patchelf --replace-needed libllama.so.0 libllama.so product/phone/libs/riscv64/libllama_napi.so
patchelf --replace-needed libggml.so.0 libggml.so product/phone/libs/riscv64/libllama_napi.so
patchelf --replace-needed libggml-base.so.0 libggml-base.so product/phone/libs/riscv64/libllama_napi.so
patchelf --replace-needed libggml-cpu.so.0 libggml-cpu.so product/phone/libs/riscv64/libllama_napi.so
```

### 5. 复制库到打包目录

```bash
# 把处理好的 .so 复制到 HAP 打包目录
cp product/phone/src/main/libs/riscv64/*.so product/phone/libs/riscv64/
```

### 6. 编译 HAP

```bash
rm -rf product/phone/build   # 清缓存，否则不会重新打包 .so
./build_settings.sh
```

### 7. 安装并测试

```bash
hdc install product/phone/build/default/outputs/default/phone-default-signed.hap
```

---

## 设备端 CLI 测试（可选）

如果想在设备上直接用命令行测试 llama.cpp：

```bash
# 上传可执行文件和库
hdc file send llama_cpp/build_riscv64/bin/llama-run /data/local/tmp/
hdc file send llama_cpp/build_riscv64/bin/lib*.so.* /data/local/tmp/
hdc file send qwen2.5-0.5b-q4.gguf /data/local/tmp/

# 设备上执行
hdc shell
cd /data/local/tmp
export LD_LIBRARY_PATH=/data/local/tmp
chmod +x llama-run
./llama-run -t 8 qwen2.5-0.5b-q4.gguf "你好"
```

## 技术实现

- `llama.cpp` 交叉编译为 RISC-V64
- NAPI 封装，提供 `loadModel()` / `generate()` / `stopGeneration()` 接口
- `generate()` 使用 `napi_create_async_work` 实现异步，返回 Promise

## 性能基线

| 设备 | 架构 | 模型 | 量化 | 速度 |
|------|------|------|------|------|
| Spacemit X60 (8核, 16GB) | RISC-V | Qwen2.5-0.5B | Q4_K_M | ~1-2 token/s |
| 紫光展锐 P7885 (4xA76+4xA55) | ARM64 | Qwen2.5-0.5B | Q4_K_M | ~5-10 token/s (预估) |

**说明：**
- Spacemit X60 没有 RVV（RISC-V Vector）向量扩展，只能标量运算
- P7885 有 NEON 向量指令，llama.cpp 原生支持，预估快 5 倍左右
- P7885 有 8 TOPS NPU，如能接入可进一步加速（需展锐 SDK）

## 目录结构
```
settings/
├── llama_cpp/                    # llama.cpp源码和编译配置
│   ├── build_riscv64.sh         # RISC-V编译脚本
│   └── ohos_riscv64.cmake       # CMake工具链
├── product/phone/
│   ├── src/main/cpp/            # NAPI封装
│   │   └── llama_napi.cpp
│   ├── src/main/ets/pages/
│   │   ├── settingList.ets      # 主列表（含AI入口）
│   │   └── aiAssistant.ets      # AI聊天页面
│   └── libs/riscv64/            # 预编译的.so库
├── build_napi.sh                # NAPI编译脚本
├── build_settings.sh            # HAP编译脚本
├── 开发历史.md                   # 详细开发记录
└── README.md                     # 本文件
```

## 移植到 ARM64 (P7885 / OpenHarmony 6.0)

如果目标设备是 ARM64 架构（如紫光展锐 P7885），需要重新编译：

### 1. 创建 ARM64 编译脚本

```bash
# 复制 RISC-V 脚本并修改
cp llama_cpp/build_riscv64.sh llama_cpp/build_arm64.sh
cp llama_cpp/ohos_riscv64.cmake llama_cpp/ohos_arm64.cmake
```

修改 `ohos_arm64.cmake`：
```cmake
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(TARGET_TRIPLE aarch64-linux-ohos)
```

修改 `build_arm64.sh`：
```bash
TARGET="aarch64-linux-ohos"
BUILD_DIR="build_arm64"
TOOLCHAIN_FILE="ohos_arm64.cmake"
```

### 2. 编译 ARM64 版本

```bash
cd llama_cpp
./build_arm64.sh
```

### 3. 处理 .so 库

```bash
# 创建 ARM64 库目录
mkdir -p product/phone/libs/arm64-v8a

# 复制并 patchelf（同 RISC-V 流程，目录改为 arm64-v8a）
cd llama_cpp/build_arm64/bin
cp libllama.so.0.0.* ../../../product/phone/src/main/libs/arm64-v8a/libllama.so
# ... 其余同 RISC-V 流程
```

### 4. 修改 build_napi.sh

修改 `TARGET` 和输出目录：
```bash
TARGET="aarch64-linux-ohos"
OUT_DIR="$SCRIPT_DIR/product/phone/libs/arm64-v8a"
LLAMA_LIB="$SCRIPT_DIR/product/phone/src/main/libs/arm64-v8a"
```

### 5. 编译并安装

```bash
./build_napi.sh
# patchelf 修复依赖（同上）
cp product/phone/src/main/libs/arm64-v8a/*.so product/phone/libs/arm64-v8a/
rm -rf product/phone/build
./build_settings.sh
hdc install product/phone/build/default/outputs/default/phone-default-signed.hap
```

---

## 测试环境

| 系统 | 设备 | 状态 |
|------|------|------|
| OpenHarmony 5.0 | Spacemit X60 (RISC-V) | ✅ 已验证 |
| OpenHarmony 6.0 | P7885 (ARM64) | 🔜 待验证 |

## License
Apache License 2.0
