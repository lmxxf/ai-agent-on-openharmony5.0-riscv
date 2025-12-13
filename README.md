# OpenHarmony Settings + AI Agent

基于OpenHarmony 5.0的系统设置应用，集成了本地AI助手功能（llama.cpp + Qwen）。

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
./hvigorw assembleHap --mode module -p product=default -p module=phone
```

产物位置：`product/phone/build/default/outputs/default/phone-default-signed.hap`

### 4. 安装到设备
```bash
hdc install product/phone/build/default/outputs/default/phone-default-signed.hap
hdc shell aa start -a com.ohos.settings.MainAbility -b com.ohos.settings
```

## AI助手功能

### 编译llama.cpp（RISC-V）
```bash
# 1. 下载llama.cpp源码到llama_cpp目录
git clone --depth 1 https://github.com/ggerganov/llama.cpp.git llama_cpp_src
cp -r llama_cpp_src/{src,include,ggml,common,cmake,vendor,tools} llama_cpp/

# 2. 运行编译脚本（需要配置OHOS SDK路径）
./llama_cpp/build_riscv64.sh
```

### 下载模型
```bash
mkdir -p models
# Qwen2.5-0.5B (测试用，470MB)
wget https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf -O models/qwen2.5-0.5b-q4.gguf
```

### 设备端测试
```bash
# 上传库和模型
hdc file send llama_cpp/build_riscv64/bin/libllama.so.0.0.929 /data/local/tmp/
hdc file send llama_cpp/build_riscv64/bin/libggml*.so.* /data/local/tmp/
hdc file send llama_cpp/build_riscv64/bin/llama-run /data/local/tmp/
hdc file send models/qwen2.5-0.5b-q4.gguf /data/local/tmp/

# 设备上执行
hdc shell
cd /data/local/tmp
ln -sf libllama.so.0.0.929 libllama.so.0
ln -sf libggml.so.0.9.4 libggml.so.0
ln -sf libggml-cpu.so.0.9.4 libggml-cpu.so.0
ln -sf libggml-base.so.0.9.4 libggml-base.so.0
chmod +x llama-run
export LD_LIBRARY_PATH=/data/local/tmp
./llama-run -t 8 qwen2.5-0.5b-q4.gguf "你好"
```

## 目录结构
```
settings/
├── llama_cpp/                    # llama.cpp编译配置
│   ├── build_riscv64.sh         # RISC-V编译脚本
│   └── ohos_riscv64.cmake       # CMake工具链
├── models/                       # 模型文件（.gitignore）
├── product/phone/src/main/ets/pages/
│   ├── settingList.ets          # 主列表（含AI入口）
│   └── aiAssistant.ets          # AI聊天页面
├── 开发历史.md                   # 开发记录
└── README.md                     # 本文件
```

## 测试环境
- **设备**: 进迭时空 RISC-V 平板 (Spacemit X60, 8核, 16GB)
- **系统**: OpenHarmony 5.0

## License
Apache License 2.0
