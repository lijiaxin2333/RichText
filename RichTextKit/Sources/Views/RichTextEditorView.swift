import SwiftUI
import UIKit
import YYText

public struct RichTextEditorView<PanelContent: View>: View {
    
    @ObservedObject private var viewModel: RichTextEditorViewModel
    @State private var coordinator: RichTextEditorCoordinator?
    
    private let placeholder: String
    private let font: UIFont
    private let textColor: UIColor
    private let panelBuilder: (RichTextTrigger, [any SuggestionItem], @escaping (any SuggestionItem) -> Void, @escaping () -> Void) -> PanelContent
    
    public init(
        viewModel: RichTextEditorViewModel,
        placeholder: String = "请输入内容...",
        font: UIFont = .systemFont(ofSize: 16),
        textColor: UIColor = .label,
        @ViewBuilder panelBuilder: @escaping (RichTextTrigger, [any SuggestionItem], @escaping (any SuggestionItem) -> Void, @escaping () -> Void) -> PanelContent
    ) {
        self.viewModel = viewModel
        self.placeholder = placeholder
        self.font = font
        self.textColor = textColor
        self.panelBuilder = panelBuilder
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
            
            if let trigger = viewModel.activeTrigger, !viewModel.suggestionItems.isEmpty {
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
        textColor: UIColor = .label
    ) {
        self.viewModel = viewModel
        self.placeholder = placeholder
        self.font = font
        self.textColor = textColor
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
        context.coordinator.textView = textView
        DispatchQueue.main.async { onCoordinatorCreated(context.coordinator) }
        return textView
    }
    
    func updateUIView(_ uiView: YYTextView, context: Context) {
    }
    
    func makeCoordinator() -> RichTextEditorCoordinator {
        RichTextEditorCoordinator(viewModel: viewModel, font: font)
    }
}

public final class RichTextEditorCoordinator: NSObject, YYTextViewDelegate {
    
    weak var textView: YYTextView?
    private let viewModel: RichTextEditorViewModel
    private let font: UIFont
    
    init(viewModel: RichTextEditorViewModel, font: UIFont) {
        self.viewModel = viewModel
        self.font = font
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
        mutable.yy_setTextBinding(binding, range: NSRange(location: triggerLocation, length: token.length))
        
        textView.attributedText = mutable
        textView.selectedRange = NSRange(location: triggerLocation + insert.length, length: 0)
        resetTypingAttributes(textView)
        viewModel.textDidChange(textView.attributedText ?? NSAttributedString())
    }
    
    private func resetTypingAttributes(_ textView: YYTextView) {
        textView.typingAttributes = [
            NSAttributedString.Key.font.rawValue: font,
            NSAttributedString.Key.foregroundColor.rawValue: UIColor.label
        ]
    }
}
