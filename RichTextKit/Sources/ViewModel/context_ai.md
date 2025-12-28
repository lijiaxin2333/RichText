# ViewModel

## 概述
状态管理层，连接 View 和数据层。

## 核心职责
- 维护输入状态与面板状态
- 解析 attributedText 为 RichTextContent
- 按触发字符触发异步拉取建议列表
- 数据回写：将 RichTextContent 转换为 attributedText

## 核心方法

### 输入处理
- `shouldChangeText(in:replacementText:currentText:)` - 拦截输入，检测触发字符
- `textDidChange(_:)` - 文本变化后解析内容

### 数据回写
- `setContent(_:)` - 将 RichTextContent 设置到编辑器
- `clearContent()` - 清空编辑器内容

### Token 创建
- `createToken(for:trigger:font:)` - 创建带属性的 token

## 数据回写流程
```
服务端数据
    ↓
RichTextContent
    ↓
viewModel.setContent(content)
    ↓
buildAttributedText() 转换为 NSAttributedString
    ↓
pendingAttributedText 触发 View 更新
    ↓
YYTextView.attributedText = pendingText
```
