import SwiftUI

public struct MentionPanel: View {
    let items: [MentionItem]
    let onSelect: (MentionItem) -> Void
    let onDismiss: () -> Void
    
    public init(items: [MentionItem], onSelect: @escaping (MentionItem) -> Void, onDismiss: @escaping () -> Void) {
        self.items = items
        self.onSelect = onSelect
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("选择联系人")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(String(item.name.prefix(1)))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                            Text(item.name)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                        .onTapGesture { onSelect(item) }
                    }
                }
            }
            .frame(maxHeight: 220)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}


