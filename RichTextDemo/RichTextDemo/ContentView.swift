import SwiftUI
import UIKit
import RichTextKit

struct ContentView: View {
    
    @StateObject private var viewModel: RichTextEditorViewModel
    @State private var showJSON = false
    @State private var tokenStyle: TokenStyle = .default
    private let config: RichTextConfiguration
    
    init() {
        let config = RichTextConfiguration()
        let mentionProvider = MockMentionProvider()
        let topicProvider = MockTopicProvider()
        
        config.register(MentionTrigger(
            dataProvider: MentionDataProviderWrapper(mentionProvider)
        ))
        config.register(TopicTrigger(
            dataProvider: TopicDataProviderWrapper(topicProvider)
        ))
        
        self.config = config
        _viewModel = StateObject(wrappedValue: RichTextEditorViewModel(configuration: config))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    editorSection
                    statusSection
                    contentPreviewSection
                    actionSection
                }
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "1a1a2e"), Color(hex: "16213e")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("富文本演示")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color(hex: "1a1a2e"))
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: "e94560"), Color(hex: "f39c12")], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text("RichTextKit")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: "e94560"), Color(hex: "f39c12")], startPoint: .leading, endPoint: .trailing)
                    )
            }
            
            Text("基于 YYTextView 的 SwiftUI 富文本输入组件")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.white.opacity(0.7))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    FeatureBadge(icon: "at", text: "@提及", color: Color(hex: "3498db"))
                    FeatureBadge(icon: "number", text: "#话题", color: Color(hex: "e67e22"))
                    FeatureBadge(icon: "shield.fill", text: "删除保护", color: Color(hex: "9b59b6"))
                    FeatureBadge(icon: "arrow.down.doc", text: "数据回写", color: Color(hex: "2ecc71"))
                    FeatureBadge(icon: "lock.open", text: "读写控制", color: Color(hex: "e74c3c"))
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }
    
    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: viewModel.isEditable ? "square.and.pencil" : "lock.fill")
                    .foregroundColor(viewModel.isEditable ? Color(hex: "e94560") : Color(hex: "e74c3c"))
                Text(viewModel.isEditable ? "编辑区域" : "只读模式")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { viewModel.isEditable.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isEditable ? "lock.open.fill" : "lock.fill")
                            .font(.system(size: 12))
                        Text(viewModel.isEditable ? "可编辑" : "只读")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(viewModel.isEditable ? Color(hex: "2ecc71") : Color(hex: "e74c3c"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(viewModel.isEditable ? Color(hex: "2ecc71").opacity(0.2) : Color(hex: "e74c3c").opacity(0.2))
                    )
                }
            }
            
            Text(viewModel.isEditable ? "输入 @ 选择联系人 · 输入 # 选择话题" : "当前为只读模式，无法编辑")
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.5))
            
            RichTextEditorView(viewModel: viewModel, placeholder: "分享你的想法...")
                .frame(minHeight: 160)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "0f3460"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "e94560").opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color(hex: "3498db"))
                Text("状态信息")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 16) {
                StatusItem(
                    label: "面板类型",
                    value: panelTypeText,
                    color: panelTypeColor
                )
                StatusItem(
                    label: "搜索关键词",
                    value: viewModel.searchKeyword.isEmpty ? "无" : "\"\(viewModel.searchKeyword)\"",
                    color: Color(hex: "f39c12")
                )
                StatusItem(
                    label: "Token 样式",
                    value: tokenStyleText,
                    color: tokenStyleColor
                )
            }
            
            Text("删除规则：先删空格 → 触发删除保护 → 再删除token")
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.4))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "16213e"))
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var contentPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundColor(Color(hex: "2ecc71"))
                Text("内容预览")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showJSON.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: showJSON ? "doc.text" : "curlybraces")
                            .font(.system(size: 12))
                        Text(showJSON ? "文本" : "JSON")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color(hex: "2ecc71").opacity(0.2))
                    )
                    .foregroundColor(Color(hex: "2ecc71"))
                }
            }
            
            if showJSON {
                jsonPreview
            } else {
                textPreview
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var textPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            PreviewRow(
                icon: "text.alignleft",
                label: "纯文本",
                content: viewModel.content.plainText.isEmpty ? "无内容" : viewModel.content.plainText,
                color: .white
            )
            
            if !viewModel.content.mentions.isEmpty {
                PreviewRow(
                    icon: "person.2.fill",
                    label: "提及 (\(viewModel.content.mentions.count))",
                    content: viewModel.content.mentions.map { $0.displayText }.joined(separator: " "),
                    color: Color(hex: "3498db")
                )
            }
            
            if !viewModel.content.topics.isEmpty {
                PreviewRow(
                    icon: "number.circle.fill",
                    label: "话题 (\(viewModel.content.topics.count))",
                    content: viewModel.content.topics.map { $0.displayText }.joined(separator: " "),
                    color: Color(hex: "e67e22")
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "0f3460").opacity(0.6))
        )
    }
    
    private var jsonPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(contentJSON)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color(hex: "2ecc71"))
                .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.4))
        )
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            tokenStyleSwitchers
            
            HStack(spacing: 16) {
                Button(action: { viewModel.clearContent() }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("清空")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "e74c3c"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "e74c3c"), lineWidth: 1.5)
                    )
                }
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("发布")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "e94560"), Color(hex: "f39c12")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: { loadMockData(type: 1) }) {
                    VStack(spacing: 4) {
                        Image(systemName: "1.circle.fill")
                            .font(.system(size: 20))
                        Text("示例1")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(Color(hex: "2ecc71"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "2ecc71"), lineWidth: 1.5)
                    )
                }
                
                Button(action: { loadMockData(type: 2) }) {
                    VStack(spacing: 4) {
                        Image(systemName: "2.circle.fill")
                            .font(.system(size: 20))
                        Text("示例2")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(Color(hex: "3498db"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "3498db"), lineWidth: 1.5)
                    )
                }
                
                Button(action: { loadMockData(type: 3) }) {
                    VStack(spacing: 4) {
                        Image(systemName: "3.circle.fill")
                            .font(.system(size: 20))
                        Text("示例3")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(Color(hex: "e67e22"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "e67e22"), lineWidth: 1.5)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private func loadMockData(type: Int) {
        let content: RichTextContent
        switch type {
        case 1:
            content = RichTextContent(items: [
                .text("大家好，我是"),
                .mention(id: "1", name: "张三"),
                .text("今天给大家推荐"),
                .topic(id: "1", name: "热门话题"),
                .text("欢迎点赞关注！")
            ])
        case 2:
            content = RichTextContent(items: [
                .text("周末活动通知："),
                .mention(id: "2", name: "李四"),
                .mention(id: "3", name: "王五"),
                .text("一起参加"),
                .topic(id: "3", name: "科技前沿"),
                .text("的线下活动吧！")
            ])
        case 3:
            content = RichTextContent(items: [
                .topic(id: "2", name: "今日推荐"),
                .text("分享给"),
                .mention(id: "4", name: "赵六"),
                .mention(id: "5", name: "钱七"),
                .mention(id: "6", name: "孙八"),
                .text("看看这个"),
                .topic(id: "4", name: "生活日常"),
                .text("真的太有趣了！")
            ])
        default:
            content = RichTextContent()
        }
        viewModel.setContent(content)
    }
    
    private var panelTypeText: String {
        guard let trigger = viewModel.activeTrigger else { return "无" }
        switch trigger.tokenType {
        case "mention": return "@提及面板"
        case "topic": return "#话题面板"
        default: return "\(trigger.triggerCharacter) 面板"
        }
    }
    
    private var panelTypeColor: Color {
        guard let trigger = viewModel.activeTrigger else { return Color.white.opacity(0.5) }
        switch trigger.tokenType {
        case "mention": return Color(hex: "3498db")
        case "topic": return Color(hex: "e67e22")
        default: return Color(trigger.tokenColor)
        }
    }
    
    private var tokenStyleText: String {
        switch tokenStyle {
        case .default: return "默认"
        case .custom: return "自定义"
        case .capsule: return "等高胶囊"
        }
    }
    
    private var tokenStyleColor: Color {
        switch tokenStyle {
        case .default: return Color.white.opacity(0.6)
        case .custom: return Color(hex: "e94560")
        case .capsule: return Color(hex: "2ecc71")
        }
    }
    
    private var contentJSON: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(viewModel.content),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "{}"
    }
    
    private func applyTokenStyle(_ style: TokenStyle) {
        tokenStyle = style
        switch style {
        case .default:
            config.unregisterToken(type: "mention")
            config.unregisterToken(type: "topic")
        case .custom:
            config.registerToken(type: "mention", config: mentionCustomConfig())
            config.registerToken(type: "topic", config: topicCustomConfig())
        case .capsule:
            config.registerToken(type: "mention", config: mentionCapsuleConfig())
            config.registerToken(type: "topic", config: topicCapsuleConfig())
        }
        viewModel.setContent(viewModel.content) // 触发当前内容重绘
    }
    
    private func mentionCustomConfig() -> RichTextTokenConfig {
        RichTextTokenConfig(
            dataBuilder: { suggestion in
                let name = suggestion.displayName
                let id = suggestion.id
                let payload = CustomTokenPayload(id: id, name: name, extra: "vip")
                let data = encodePayload(payload) ?? id
                return RichTextItem(type: "mention", displayText: "@\(name)", data: data)
            },
            payloadDecoder: { data in decodePayload(data)?.asDict },
            viewBuilder: { context, _ in
                let name = context.payload?["name"] ?? context.item.displayText.replacingOccurrences(of: "@", with: "")
                let id = context.payload?["id"] ?? context.item.data
                return RichTextTokenView(
                    HStack(spacing: 8) {
                        Circle()
                            .fill(
                                LinearGradient(colors: [Color(hex: "e94560"), Color(hex: "3498db")],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            )
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text(String(name.prefix(1)))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text("ID: \(id)")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                    )
                )
            }
        )
    }
    
    private func topicCustomConfig() -> RichTextTokenConfig {
        RichTextTokenConfig(
            dataBuilder: { suggestion in
                let name = suggestion.displayName
                let id = suggestion.id
                let payload = CustomTokenPayload(id: id, name: name, extra: "hot")
                let data = encodePayload(payload) ?? id
                return RichTextItem(type: "topic", displayText: "#\(name)#", data: data)
            },
            payloadDecoder: { data in decodePayload(data)?.asDict },
            viewBuilder: { context, _ in
                let name = context.payload?["name"] ?? context.item.displayText.replacingOccurrences(of: "#", with: "")
                let id = context.payload?["id"] ?? context.item.data
                return RichTextTokenView(
                    HStack(spacing: 8) {
                        Text("#")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(colors: [Color(hex: "f39c12"), Color(hex: "e67e22")],
                                                       startPoint: .topLeading,
                                                       endPoint: .bottomTrailing)
                                    )
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text("话题ID: \(id)")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "e67e22").opacity(0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "f39c12").opacity(0.35), lineWidth: 1)
                            )
                    )
                )
            }
        )
    }
    
    private func encodePayload(_ payload: CustomTokenPayload) -> String? {
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func decodePayload(_ text: String) -> CustomTokenPayload? {
        guard let data = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(CustomTokenPayload.self, from: data)
    }
    
    private func mentionCapsuleConfig() -> RichTextTokenConfig {
        RichTextTokenConfig(
            dataBuilder: { suggestion in
                let name = suggestion.displayName
                let id = suggestion.id
                let payload = CapsuleTokenPayload(id: id, name: name, avatarSeed: suggestion.id, icon: "bolt.fill")
                let data = encodeCapsulePayload(payload) ?? id
                return RichTextItem(type: "mention", displayText: "@\(name)", data: data)
            },
            payloadDecoder: { data in decodeCapsulePayload(data)?.asDict },
            viewBuilder: { context, font in
                capsuleTokenView(context: context, font: font)
            }
        )
    }
    
    private func topicCapsuleConfig() -> RichTextTokenConfig {
        RichTextTokenConfig(
            dataBuilder: { suggestion in
                let name = suggestion.displayName
                let id = suggestion.id
                let payload = CapsuleTokenPayload(id: id, name: name, avatarSeed: suggestion.id, icon: "tag")
                let data = encodeCapsulePayload(payload) ?? id
                return RichTextItem(type: "topic", displayText: "#\(name)#", data: data)
            },
            payloadDecoder: { data in decodeCapsulePayload(data)?.asDict },
            viewBuilder: { context, font in
                capsuleTokenView(context: context, font: font)
            }
        )
    }
    
    @ViewBuilder
    private func capsuleTokenView(context: RichTextTokenRenderContext, font: UIFont) -> RichTextTokenView? {
        let name = context.payload?["name"] ?? context.item.displayText
        let id = context.payload?["id"] ?? context.item.data
        let seed = context.payload?["avatarSeed"] ?? id
        let icon = context.payload?["icon"] ?? "bolt.fill"
        let lineHeight = font.lineHeight
        let avatarSize = lineHeight * 0.8
        let paddingX = lineHeight * 0.35
        
        return RichTextTokenView(
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: "https://picsum.photos/seed/\(seed)/80")) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure(_):
                        Color.gray.opacity(0.3)
                    case .empty:
                        Color.gray.opacity(0.2)
                    @unknown default:
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
                
                Text(name)
                    .font(.system(size: font.pointSize, weight: .semibold))
                    .foregroundColor(.white)
                Text(id)
                    .font(.system(size: font.pointSize * 0.9))
                    .foregroundColor(.white.opacity(0.8))
                Image(systemName: icon)
                    .font(.system(size: font.pointSize * 0.9, weight: .bold))
                    .foregroundColor(Color(hex: "f1c40f"))
            }
            .padding(.horizontal, paddingX)
            .frame(height: lineHeight)
            .background(
                Capsule()
                    .fill(Color(hex: "0f3460"))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.8)
                    )
            )
        )
    }
    
    private func encodeCapsulePayload(_ payload: CapsuleTokenPayload) -> String? {
        guard let data = try? JSONEncoder().encode(payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func decodeCapsulePayload(_ text: String) -> CapsuleTokenPayload? {
        guard let data = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(CapsuleTokenPayload.self, from: data)
    }
}

struct FeatureBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

struct StatusItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(Color.white.opacity(0.5))
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

struct PreviewRow: View {
    let icon: String
    let label: String
    let content: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color.opacity(0.8))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.5))
                Text(content)
                    .font(.system(size: 13))
                    .foregroundColor(color)
                    .lineLimit(3)
            }
        }
    }
}

private enum TokenStyle {
    case `default`
    case custom
    case capsule
}

extension ContentView {
    private var tokenStyleSwitchers: some View {
        HStack(spacing: 10) {
            tokenStyleButton(title: "默认样式", systemImage: "circle", style: .default, colors: [Color(hex: "95a5a6"), Color(hex: "7f8c8d")])
            tokenStyleButton(title: "自定义样式", systemImage: "paintbrush", style: .custom, colors: [Color(hex: "e94560"), Color(hex: "3498db")])
            tokenStyleButton(title: "等高胶囊", systemImage: "capsule.fill", style: .capsule, colors: [Color(hex: "2ecc71"), Color(hex: "27ae60")])
        }
    }
    
    private func tokenStyleButton(title: String, systemImage: String, style: TokenStyle, colors: [Color]) -> some View {
        Button(action: { applyTokenStyle(style) }) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                    .opacity(tokenStyle == style ? 1.0 : 0.55)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(tokenStyle == style ? 0.35 : 0.2), lineWidth: tokenStyle == style ? 1.2 : 0.6)
            )
            .cornerRadius(10)
        }
    }
}

struct CustomTokenPayload: Codable {
    let id: String
    let name: String
    let extra: String?
    
    var asDict: [String: String] {
        var result: [String: String] = ["id": id, "name": name]
        if let extra = extra { result["extra"] = extra }
        return result
    }
}

struct CapsuleTokenPayload: Codable {
    let id: String
    let name: String
    let avatarSeed: String
    let icon: String
    
    var asDict: [String: String] {
        [
            "id": id,
            "name": name,
            "avatarSeed": avatarSeed,
            "icon": icon
        ]
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
