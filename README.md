# OpenHarmony Settings + AI Agent

基于OpenHarmony 5.0的系统设置应用，集成了本地AI助手功能（llama.cpp + Qwen）。

## 特性

- 完全本地运行，无需联网，保护用户隐私
- 支持多轮对话（保留最近3轮历史）
- 异步推理，不阻塞UI

## 前置要求

- OpenHarmony SDK 12（含 RISC-V 工具链）
- CMake 3.14+
- patchelf
- hdc 命令行工具

## 快速开始（使用预编译库）

如果只是想快速体验，可以直接使用仓库中预编译的 .so 库。

### 1. 克隆仓库
```bash
git clone git@github.com:lmxxf/ai-agent-on-openharmony5.0-riscv.git
cd ai-agent-on-openharmony5.0-riscv
```

### 2. 配置SDK路径
```bash
# 创建local.properties，指向你的OpenHarmony SDK
echo "sdk.dir=/path/to/ohos-sdk/linux" > local.properties
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

### 1. 编译 llama.cpp (RISC-V64)

```bash
# llama.cpp 源码已包含在 llama_cpp/ 目录
cd llama_cpp
./build_riscv64.sh
```

编译产物在 `llama_cpp/build_riscv64/bin/`，包括：
- `libllama.so.0`
- `libggml.so.0`
- `libggml-base.so.0`
- `libggml-cpu.so.0`

### 2. 处理 .so 库（去除版本号）

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

### 3. 编译 NAPI wrapper

```bash
cd /path/to/settings
./build_napi.sh

# 修复 NAPI .so 的依赖
patchelf --replace-needed libllama.so.0 libllama.so product/phone/libs/riscv64/libllama_napi.so
patchelf --replace-needed libggml.so.0 libggml.so product/phone/libs/riscv64/libllama_napi.so
patchelf --replace-needed libggml-base.so.0 libggml-base.so product/phone/libs/riscv64/libllama_napi.so
patchelf --replace-needed libggml-cpu.so.0 libggml-cpu.so product/phone/libs/riscv64/libllama_napi.so
```

### 4. 复制库到打包目录

```bash
# 把处理好的 .so 复制到 HAP 打包目录
cp product/phone/src/main/libs/riscv64/*.so product/phone/libs/riscv64/
```

### 5. 编译 HAP

```bash
rm -rf product/phone/build   # 清缓存，否则不会重新打包 .so
./build_settings.sh
```

### 6. 安装并测试

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

| 设备 | 模型 | 量化 | 速度 |
|------|------|------|------|
| Spacemit X60 (RISC-V, 8核, 16GB) | Qwen2.5-0.5B | Q4_K_M | ~1-2 token/s |

注：Spacemit X60 没有 RVV 向量扩展，这是硬件极限。

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

## 测试环境
- **设备**: 进迭时空 RISC-V 平板 (Spacemit X60, 8核, 16GB)
- **系统**: OpenHarmony 5.0

## License
Apache License 2.0
