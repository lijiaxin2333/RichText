# RichTextKit

## Plan
- 基于 YYTextView 封装 SwiftUI 富文本输入
- 支持 @mention 与 #topic 的面板选择与插入
- token 使用 YYTextBinding(deleteConfirm: true) 实现删除保护
- 删除语义：token 后跟普通空格；第一次退格删空格；再退格触发删除保护；再退格真正删除 token

## 架构

```
RichTextKit/
├── Configuration/          # 配置模块
│   └── RichTextConfiguration.swift   # 触发器容器
├── Triggers/               # 触发器模块（可扩展）
│   ├── RichTextTrigger.swift         # 触发器协议
│   ├── MentionTrigger.swift          # @ 默认实现
│   └── TopicTrigger.swift            # # 默认实现
├── Models/                 # 数据模型
├── Protocols/              # 数据提供者协议
├── ViewModel/              # 状态管理
└── Views/                  # 视图层
```

## 扩展触发器
```swift
// 1. 实现 RichTextTrigger 协议
struct CustomTrigger: RichTextTrigger {
    let triggerCharacter = "$"
    let tokenType = "custom"
    let tokenFormat = "${name}"
    let tokenColor = UIColor.green
    let dataProvider: SuggestionDataProvider
}

// 2. 注册到配置
let config = RichTextConfiguration()
config.register(CustomTrigger(...))

// 3. 使用配置创建 ViewModel
let viewModel = RichTextEditorViewModel(configuration: config)
```
