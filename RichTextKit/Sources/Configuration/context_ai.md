# Configuration

## 概述
配置模块，管理触发器注册和查询。

## 核心类
- `RichTextConfiguration`: 配置中心，管理触发器容器

## 使用方式
```swift
let config = RichTextConfiguration()
config.register(MentionTrigger(...))
config.register(TopicTrigger(...))
config.register(CustomTrigger(...))  // 自定义触发器

let viewModel = RichTextEditorViewModel(configuration: config)
```

## 便捷方法
- `defaultConfiguration(factory:)`: 创建包含默认 @# 触发器的配置

