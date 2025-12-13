/**
 * Copyright (c) 2024 OpenHarmony Contributors
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

import Router from '@system.router';
import ConfigData from '../../../../../../common/utils/src/main/ets/default/baseUtil/ConfigData';
import LogUtil from '../../../../../../common/utils/src/main/ets/default/baseUtil/LogUtil';
import HeadComponent from '../../../../../../common/component/src/main/ets/default/headComponent';

interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
  timestamp: number;
}

@Entry
@Component
struct AiAssistant {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = false;
  @State modelStatus: string = '模型未加载';
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    LogUtil.info('AiAssistant aboutToAppear');
    // TODO: 初始化MindSpore Lite模型
    this.modelStatus = '等待加载模型...';
  }

  build() {
    Column() {
      // 顶部导航栏
      HeadComponent({ headName: $r('app.string.ai_assistant'), isActive: true })

      // 模型状态
      Row() {
        Circle()
          .width(8)
          .height(8)
          .fill(this.modelStatus.includes('已加载') ? '#52c41a' : '#faad14')
        Text(this.modelStatus)
          .fontSize(12)
          .fontColor('#666666')
          .margin({ left: 8 })
      }
      .width(ConfigData.WH_100_100)
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor('#f5f5f5')

      // 聊天消息列表
      Scroll(this.scroller) {
        Column() {
          if (this.messages.length === 0) {
            // 欢迎界面
            Column() {
              Image($r('app.media.ic_ai'))
                .width(80)
                .height(80)
                .margin({ top: 60 })
              Text('AI 助手')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 16 })
              Text('基于 Qwen3-1.7B 本地模型')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 8 })
              Text('在设备端运行，保护您的隐私')
                .fontSize(12)
                .fontColor('#cccccc')
                .margin({ top: 4 })
            }
            .width(ConfigData.WH_100_100)
            .alignItems(HorizontalAlign.Center)
          } else {
            ForEach(this.messages, (msg: ChatMessage, index: number) => {
              this.MessageBubble(msg)
            })
          }

          if (this.isLoading) {
            Row() {
              LoadingProgress()
                .width(20)
                .height(20)
              Text('AI正在思考...')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ left: 8 })
            }
            .margin({ top: 12, bottom: 12 })
          }
        }
        .width(ConfigData.WH_100_100)
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // 输入区域
      Row() {
        TextInput({ placeholder: '输入消息...', text: this.inputText })
          .layoutWeight(1)
          .height(44)
          .borderRadius(22)
          .backgroundColor('#f0f0f0')
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.inputText = value;
          })
          .onSubmit(() => {
            this.sendMessage();
          })

        Button() {
          Image($r('app.media.ic_ok'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
        }
        .width(44)
        .height(44)
        .borderRadius(22)
        .backgroundColor(this.inputText.length > 0 ? '#007AFF' : '#cccccc')
        .margin({ left: 8 })
        .enabled(this.inputText.length > 0 && !this.isLoading)
        .onClick(() => {
          this.sendMessage();
        })
      }
      .width(ConfigData.WH_100_100)
      .padding({ left: 16, right: 16, top: 8, bottom: 16 })
      .backgroundColor(Color.White)
    }
    .width(ConfigData.WH_100_100)
    .height(ConfigData.WH_100_100)
    .backgroundColor('#f5f5f5')
  }

  @Builder
  MessageBubble(msg: ChatMessage) {
    Row() {
      if (msg.role === 'assistant') {
        Image($r('app.media.ic_ai'))
          .width(32)
          .height(32)
          .margin({ right: 8 })
      }

      Column() {
        Text(msg.content)
          .fontSize(15)
          .fontColor(msg.role === 'user' ? Color.White : '#333333')
          .textAlign(msg.role === 'user' ? TextAlign.End : TextAlign.Start)
      }
      .padding(12)
      .borderRadius(16)
      .backgroundColor(msg.role === 'user' ? '#007AFF' : Color.White)
      .constraintSize({ maxWidth: '75%' })

      if (msg.role === 'user') {
        Image($r('app.media.app_icon'))
          .width(32)
          .height(32)
          .margin({ left: 8 })
          .borderRadius(16)
      }
    }
    .width(ConfigData.WH_100_100)
    .justifyContent(msg.role === 'user' ? FlexAlign.End : FlexAlign.Start)
    .margin({ top: 12 })
  }

  sendMessage() {
    if (this.inputText.trim().length === 0 || this.isLoading) {
      return;
    }

    const userMessage: ChatMessage = {
      role: 'user',
      content: this.inputText.trim(),
      timestamp: Date.now()
    };
    this.messages.push(userMessage);
    this.inputText = '';
    this.isLoading = true;

    // 滚动到底部
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 100);

    // TODO: 调用MindSpore Lite推理
    // 目前用模拟响应
    setTimeout(() => {
      const assistantMessage: ChatMessage = {
        role: 'assistant',
        content: this.generateMockResponse(userMessage.content),
        timestamp: Date.now()
      };
      this.messages.push(assistantMessage);
      this.isLoading = false;

      setTimeout(() => {
        this.scroller.scrollEdge(Edge.Bottom);
      }, 100);
    }, 1000);
  }

  generateMockResponse(input: string): string {
    // 模拟响应，后续替换为真实的模型推理
    if (input.includes('你好') || input.includes('hello')) {
      return '你好！我是运行在本地的AI助手，基于Qwen3-1.7B模型。有什么我可以帮助你的吗？';
    } else if (input.includes('天气')) {
      return '抱歉，我目前无法获取实时天气信息。作为本地模型，我没有联网能力。';
    } else if (input.includes('是谁') || input.includes('介绍')) {
      return '我是一个运行在OpenHarmony设备上的本地AI助手。我使用Qwen3-1.7B模型，通过MindSpore Lite在设备端进行推理，所有对话数据都在本地处理，保护您的隐私。';
    } else {
      return `收到您的消息："${input}"\n\n模型推理功能正在开发中，敬请期待！`;
    }
  }
}
