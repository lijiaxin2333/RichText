import SwiftUI
import UIKit
import RichTextKit

struct ContentView: View {
    
    @StateObject private var viewModel = RichTextEditorViewModel(factory: MockSuggestionProviderFactory())
    @State private var showJSON = false
    
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
            
            HStack(spacing: 16) {
                FeatureBadge(icon: "at", text: "@提及", color: Color(hex: "3498db"))
                FeatureBadge(icon: "number", text: "#话题", color: Color(hex: "e67e22"))
                FeatureBadge(icon: "shield.fill", text: "删除保护", color: Color(hex: "9b59b6"))
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }
    
    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(Color(hex: "e94560"))
                Text("编辑区域")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text("输入 @ 选择联系人 · 输入 # 选择话题")
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
        HStack(spacing: 16) {
            Button(action: {}) {
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
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var panelTypeText: String {
        switch viewModel.suggestionPanelType {
        case .none: return "无"
        case .mention: return "@提及面板"
        case .topic: return "#话题面板"
        }
    }
    
    private var panelTypeColor: Color {
        switch viewModel.suggestionPanelType {
        case .none: return Color.white.opacity(0.5)
        case .mention: return Color(hex: "3498db")
        case .topic: return Color(hex: "e67e22")
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
