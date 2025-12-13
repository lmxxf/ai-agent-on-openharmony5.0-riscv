# OpenHarmony Settings + AI Agent

基于OpenHarmony 5.0的系统设置应用，集成了本地AI助手功能（llama.cpp + Qwen）。

## 特性

- 完全本地运行，无需联网，保护用户隐私
- 支持多轮对话（保留最近3轮历史）
- 异步推理，不阻塞UI

## 快速开始

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

### 5. 准备模型文件
```bash
# 将模型复制到设备
hdc file send qwen2.5-0.5b-q4.gguf /data/app/el2/100/base/com.ohos.settings/files/
```

### 6. 使用AI助手
打开设置应用 → 点击"AI助手"入口 → 等待模型加载完成后即可对话

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
