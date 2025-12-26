import SwiftUI

public struct TopicPanel: View {
    let items: [TopicItem]
    let onSelect: (TopicItem) -> Void
    let onDismiss: () -> Void
    
    public init(items: [TopicItem], onSelect: @escaping (TopicItem) -> Void, onDismiss: @escaping () -> Void) {
        self.items = items
        self.onSelect = onSelect
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("选择话题")
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
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 36, height: 36)
                                Text("#")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)
                                if item.count > 0 {
                                    Text("\(item.count) 条讨论")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
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


