# RichText

## Plan
- 重建 RichTextKit：SPM 包内置 YYText，提供基于 YYTextView 的富文本输入组件
- 触发面板：输入 @ 拉起联系人面板，输入 # 拉起话题面板
- 插入 token：插入高亮文本并使用 YYTextBinding(deleteConfirm: true) 做删除保护
- 删除语义：token 后有一个普通空格；第一次退格删空格；再退格触发删除保护；再退格真正删除 token
- 重建 RichTextDemo：使用 xcodegen 生成主 App，引用 RichTextKit，提供 mock 数据演示


