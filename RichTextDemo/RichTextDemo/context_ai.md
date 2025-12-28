# RichTextDemo

## 概述
RichTextKit 的功能演示 App，展示富文本编辑器的完整功能。

## 功能演示
- @mention 提及功能：输入 @ 触发联系人选择面板
- #topic 话题功能：输入 # 触发话题选择面板
- 删除保护：token 使用 YYTextBinding 实现删除确认机制
- 内容解析：实时预览解析后的纯文本、提及、话题列表
- JSON 输出：展示结构化的内容数据格式

## 架构
- ContentView: 主演示界面，展示编辑器和内容预览
- MockFactory: 提供模拟数据的 SuggestionProviderFactory 实现

## 依赖
- 使用 Factory 模式通过 MockSuggestionProviderFactory 注入数据提供者
- 遵循 MVVM 模式，使用 RichTextEditorViewModel 管理状态

