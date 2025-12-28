# Triggers

## 概述
触发器模块，定义可扩展的触发机制。

## 核心协议
- `RichTextTrigger`: 触发器协议，定义触发字符、token类型、格式、颜色、数据提供者
- `SuggestionItem`: 建议项协议
- `SuggestionDataProvider`: 数据提供者协议

## 默认实现
- `MentionTrigger`: @ 触发器
- `TopicTrigger`: # 触发器

## 扩展方式
业务方可自定义触发器，实现 `RichTextTrigger` 协议后通过 `RichTextConfiguration.register()` 注册。

