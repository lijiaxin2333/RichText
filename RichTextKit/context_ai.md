# RichTextKit

## Plan
- 基于 YYTextView 封装 SwiftUI 富文本输入
- 支持 @mention 与 #topic 的面板选择与插入
- token 使用 YYTextBinding(deleteConfirm: true) 实现删除保护
- 删除语义：token 后跟普通空格；第一次退格删空格；再退格触发删除保护；再退格真正删除 token


