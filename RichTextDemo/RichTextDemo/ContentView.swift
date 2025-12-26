import SwiftUI
import RichTextKit

struct ContentView: View {
    
    @StateObject private var viewModel = RichTextEditorViewModel(factory: MockSuggestionProviderFactory())
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("输入 @ 选择联系人，输入 # 选择话题")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    
                    RichTextEditorView(viewModel: viewModel, placeholder: "分享你的想法...")
                        .frame(minHeight: 180)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    
                    Text("删除规则：先删空格，再触发删除保护，再删 token")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("内容预览")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(viewModel.content.plainText.isEmpty ? "无内容" : viewModel.content.plainText)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .lineLimit(3)
                        
                        if !viewModel.content.mentions.isEmpty {
                            Text(viewModel.content.mentions.map { $0.displayText }.joined(separator: ", "))
                                .font(.system(size: 13))
                                .foregroundColor(.blue)
                        }
                        
                        if !viewModel.content.topics.isEmpty {
                            Text(viewModel.content.topics.map { $0.displayText }.joined(separator: ", "))
                                .font(.system(size: 13))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                }
                .padding(16)
                
                Spacer()
            }
            .navigationTitle("富文本编辑器")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


