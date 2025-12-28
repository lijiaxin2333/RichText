import SwiftUI

public struct DefaultSuggestionPanel: View {
    let trigger: RichTextTrigger
    let items: [any SuggestionItem]
    let onSelect: (any SuggestionItem) -> Void
    let onDismiss: () -> Void
    
    public init(
        trigger: RichTextTrigger,
        items: [any SuggestionItem],
        onSelect: @escaping (any SuggestionItem) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.trigger = trigger
        self.items = items
        self.onSelect = onSelect
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(panelTitle)
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
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        HStack(spacing: 12) {
                            itemIcon
                            Text(item.displayName)
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
    
    private var panelTitle: String {
        switch trigger.tokenType {
        case "mention":
            return "选择联系人"
        case "topic":
            return "选择话题"
        default:
            return "选择 \(trigger.triggerCharacter)"
        }
    }
    
    @ViewBuilder
    private var itemIcon: some View {
        switch trigger.tokenType {
        case "mention":
            Circle()
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(trigger.triggerCharacter)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )
        case "topic":
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(trigger.triggerCharacter)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                )
        default:
            Circle()
                .fill(Color(trigger.tokenColor))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(trigger.triggerCharacter)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )
        }
    }
}

