# Settings<a name="ZH-CN_TOPIC_0000001103421572"></a>

-   [简介](#section11660541593)
    -   [架构图](#section48896451454)
    -   [AI助手功能](#ai-assistant)

-   [目录](#section161941989596)
-   [相关仓](#section1371113476307)

## 简介<a name="section11660541593"></a>

设置应用是 OpenHarmony 系统中预置的系统应用，为用户提供设置系统属性的交互界面，例如设置系统时间，屏幕亮度等系统属性。

### AI助手功能<a name="ai-assistant"></a>

本分支新增了本地AI助手功能，基于 llama.cpp 和 Qwen2.5-0.5B 模型实现设备端推理。

**特性：**
- 完全本地运行，无需联网，保护用户隐私
- 支持多轮对话（保留最近3轮历史）
- 异步推理，不阻塞UI

**技术实现：**
- `llama.cpp` 交叉编译为 RISC-V64
- NAPI 封装，提供 `loadModel()` / `generate()` / `stopGeneration()` 接口
- `generate()` 使用 `napi_create_async_work` 实现异步，返回 Promise

**测试设备：**
- 进迭时空 RISC-V 平板 (Spacemit X60, 8核, 16GB)

**使用方法：**
1. 将模型文件 `qwen2.5-0.5b-q4.gguf` 复制到设备的 `/data/app/el2/100/base/com.ohos.settings/files/`
2. 打开设置应用，点击"AI助手"入口
3. 等待模型加载完成后即可对话

详细开发记录见 [开发历史.md](开发历史.md)

### 架构图<a name="section48896451454"></a>

![](figures/zh-cn_image_0000001153225717.png)

## 目录<a name="section161941989596"></a>

```
/applications/standard/settings
├── entry             # 主entry模块目录
│   └── src
│       ├── main
│           ├── ets               # ets模块目录
│               ├── default
│                   ├── common    # 公共工具存放目录
│                   ├── model     # 数据管理和决策逻辑存放目录
│                   ├── pages     # 组件页面存放目录
│                   ├── res       # 部分图片资源
│                   ├── resources # 其它共用资源
│                   ├── app.ets   # 全局ets逻辑和应用生命周期管理文件
│           ├── resources         # 资源配置文件存放目录
│               ├── base          # 默认语言场景，图片资源，字体大小，颜色资源内容存放目录
│               ├── en_AS.element # 英文语言场景资源内容存放目录
│               ├── rawfile       # 本地配置文件存放目录
│               ├── zh_CN.element # 中文语言场景资源内容存放目录
│           └── config.json       # 全局配置文件
├── signature              # 证书文件目录
├── LICENSE                # 许可文件
```

## 相关仓<a name="section1371113476307"></a>

系统应用

**applications\_settings**

