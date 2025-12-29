import SwiftUI
import UIKit
import YYText
import Combine

public struct RichTextEditorView<PanelContent: View>: View {
    
    @ObservedObject private var viewModel: RichTextEditorViewModel
    @State private var coordinator: RichTextEditorCoordinator?
    
    private let placeholder: String
    private let font: UIFont
    private let textColor: UIColor
    private let onTokenTap: ((RichTextItem) -> Void)?
    private let panelBuilder: (RichTextTrigger, [any SuggestionItem], @escaping (any SuggestionItem) -> Void, @escaping () -> Void) -> PanelContent
    
    public init(
        viewModel: RichTextEditorViewModel,
        placeholder: String = "请输入内容...",
        font: UIFont = .systemFont(ofSize: 16),
        textColor: UIColor = .label,
        onTokenTap: ((RichTextItem) -> Void)? = nil,
        @ViewBuilder panelBuilder: @escaping (RichTextTrigger, [any SuggestionItem], @escaping (any SuggestionItem) -> Void, @escaping () -> Void) -> PanelContent
    ) {
        self.viewModel = viewModel
        self.placeholder = placeholder
        self.font = font
        self.textColor = textColor
        self.onTokenTap = onTokenTap
        self.panelBuilder = panelBuilder
        viewModel.setFont(font)
        viewModel.onTokenTap = onTokenTap
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            YYTextEditorRepresentable(
                viewModel: viewModel,
                placeholder: placeholder,
                font: font,
                textColor: textColor,
                onCoordinatorCreated: { coordinator in
                    self.coordinator = coordinator
                }
            )
            
            if viewModel.isEditable, let trigger = viewModel.activeTrigger, !viewModel.suggestionItems.isEmpty {
                panelBuilder(
                    trigger,
                    viewModel.suggestionItems,
                    { item in
                        coordinator?.insertToken(item: item, trigger: trigger)
                        viewModel.dismissSuggestionPanel()
                    },
                    { viewModel.dismissSuggestionPanel() }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }
}

public extension RichTextEditorView where PanelContent == AnyView {
    
    init(
        viewModel: RichTextEditorViewModel,
        placeholder: String = "请输入内容...",
        font: UIFont = .systemFont(ofSize: 16),
        textColor: UIColor = .label,
        onTokenTap: ((RichTextItem) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.placeholder = placeholder
        self.font = font
        self.textColor = textColor
        self.onTokenTap = onTokenTap
        self.panelBuilder = { trigger, items, onSelect, onDismiss in
            AnyView(
                DefaultSuggestionPanel(
                    trigger: trigger,
                    items: items,
                    onSelect: onSelect,
                    onDismiss: onDismiss
                )
            )
        }
        viewModel.setFont(font)
        viewModel.onTokenTap = onTokenTap
    }
}

struct YYTextEditorRepresentable: UIViewRepresentable {
    
    @ObservedObject var viewModel: RichTextEditorViewModel
    let placeholder: String
    let font: UIFont
    let textColor: UIColor
    let onCoordinatorCreated: (RichTextEditorCoordinator) -> Void
    
    func makeUIView(context: Context) -> YYTextView {
        let textView = YYTextView()
        textView.delegate = context.coordinator
        textView.font = font
        textView.textColor = textColor
        textView.placeholderText = placeholder
        textView.placeholderFont = font
        textView.placeholderTextColor = .placeholderText
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        // 确保在只读模式下依然可点击高亮（token 点击依赖 highlightable/selectable）。
        textView.isSelectable = true
        textView.isHighlightable = true
        textView.isEditable = viewModel.isEditable
        context.coordinator.textView = textView
        context.coordinator.setupObservers()
        DispatchQueue.main.async { onCoordinatorCreated(context.coordinator) }
        return textView
    }
    
    func updateUIView(_ uiView: YYTextView, context: Context) {
        if uiView.isEditable != viewModel.isEditable {
            uiView.isEditable = viewModel.isEditable
        }
    }
    
    func makeCoordinator() -> RichTextEditorCoordinator {
        RichTextEditorCoordinator(viewModel: viewModel, font: font)
    }
}

public final class RichTextEditorCoordinator: NSObject, YYTextViewDelegate {
    
    weak var textView: YYTextView?
    private let viewModel: RichTextEditorViewModel
    private let font: UIFont
    private var cancellables = Set<AnyCancellable>()
    private weak var tokenTapGesture: UITapGestureRecognizer?
    
    init(viewModel: RichTextEditorViewModel, font: UIFont) {
        self.viewModel = viewModel
        self.font = font
    }
    
    func setupObservers() {
        viewModel.$pendingAttributedText
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] attributedText in
                self?.applyPendingText(attributedText)
            }
            .store(in: &cancellables)
        
        setupTokenTapGestureIfNeeded()
    }

    private func setupTokenTapGestureIfNeeded() {
        guard let textView, tokenTapGesture == nil else { return }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTokenTap(_:)))
        tap.cancelsTouchesInView = false
        textView.addGestureRecognizer(tap)
        tokenTapGesture = tap
    }

    /// YYTextView 内部只有在「非编辑态（非 firstResponder）」才会命中 highlight；
    /// 这里补齐「编辑态」下 token 的点击命中能力。
    @objc private func handleTokenTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, let textView else { return }
        // 避免和 YYTextView 自带的 highlight 点击（非编辑态）重复触发。
        guard textView.isFirstResponder else { return }
        guard let attributedText = textView.attributedText, attributedText.length > 0 else { return }
        guard let layout = textView.textLayout else { return }

        let locationInView = gesture.location(in: textView)
        // YYTextView 内部使用 containerView 坐标；在 UIScrollView 场景下需要加上 contentOffset。
        let pointInContainer = CGPoint(
            x: locationInView.x + textView.contentOffset.x,
            y: locationInView.y + textView.contentOffset.y
        )

        guard let textRange = layout.textRange(at: pointInContainer) ?? layout.closestTextRange(at: pointInContainer) else { return }
        let index = textRange.start.offset
        guard index != NSNotFound, index < attributedText.length else { return }

        var effective = NSRange(location: 0, length: 0)
        let attrs = attributedText.attributes(at: index, effectiveRange: &effective)
        guard
            let type = attrs[.richTextItemType] as? String,
            let id = attrs[.richTextItemId] as? String
        else { return }

        let displayText: String
        if let stored = attrs[.richTextItemDisplayText] as? String, !stored.isEmpty {
            displayText = stored
        } else {
            displayText = (attributedText.string as NSString).substring(with: effective)
        }

        viewModel.handleTokenTap(item: RichTextItem(type: type, displayText: displayText, data: id))
    }
    
    private func applyPendingText(_ attributedText: NSAttributedString) {
        guard let textView = textView else { return }
        textView.attributedText = attributedText
        textView.selectedRange = NSRange(location: attributedText.length, length: 0)
        resetTypingAttributes(textView)
        viewModel.clearPendingText()
        viewModel.textDidChange(textView.attributedText ?? NSAttributedString())
    }
    
    public func textView(_ textView: YYTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return viewModel.shouldChangeText(
            in: range,
            replacementText: text,
            currentText: textView.attributedText ?? NSAttributedString()
        )
    }
    
    public func textViewDidChange(_ textView: YYTextView) {
        viewModel.textDidChange(textView.attributedText ?? NSAttributedString())
    }
    
    @MainActor
    func insertToken(item: any SuggestionItem, trigger: RichTextTrigger) {
        guard let textView = textView else { return }
        let triggerLocation = viewModel.getTriggerLocation()
        let currentLocation = textView.selectedRange.location
        let rangeToReplace = NSRange(location: triggerLocation, length: max(0, currentLocation - triggerLocation))
        
        let token = viewModel.createToken(for: item, trigger: trigger, font: font)
        let insert = NSMutableAttributedString(attributedString: token)
        insert.append(NSAttributedString(string: " ", attributes: [.font: font, .foregroundColor: UIColor.label]))
        
        let mutable = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
        mutable.replaceCharacters(in: rangeToReplace, with: insert)
        
        let binding = YYTextBinding(deleteConfirm: true)
        mutable.yy_setTextBinding(binding, range: NSRange(location: triggerLocation, length: insert.length))
        
        textView.attributedText = mutable
        textView.selectedRange = NSRange(location: triggerLocation + insert.length, length: 0)
        resetTypingAttributes(textView)
        viewModel.textDidChange(textView.attributedText ?? NSAttributedString())
    }
    
    func resetTypingAttributes(_ textView: YYTextView) {
        textView.typingAttributes = [
            NSAttributedString.Key.font.rawValue: font,
            NSAttributedString.Key.foregroundColor.rawValue: UIColor.label
        ]
    }
}
