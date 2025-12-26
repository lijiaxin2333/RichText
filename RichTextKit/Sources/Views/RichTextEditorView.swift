import SwiftUI
import UIKit
import YYText

public struct RichTextEditorView: View {
    
    @StateObject private var viewModel: RichTextEditorViewModel
    @State private var coordinator: RichTextEditorCoordinator?
    
    private let placeholder: String
    private let font: UIFont
    private let textColor: UIColor
    
    public init(viewModel: RichTextEditorViewModel, placeholder: String = "请输入内容...", font: UIFont = .systemFont(ofSize: 16), textColor: UIColor = .label) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.placeholder = placeholder
        self.font = font
        self.textColor = textColor
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
            
            if viewModel.suggestionPanelType == .mention && !viewModel.mentionItems.isEmpty {
                MentionPanel(
                    items: viewModel.mentionItems,
                    onSelect: { item in
                        coordinator?.insertMention(item)
                        viewModel.dismissSuggestionPanel()
                    },
                    onDismiss: { viewModel.dismissSuggestionPanel() }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            
            if viewModel.suggestionPanelType == .topic && !viewModel.topicItems.isEmpty {
                TopicPanel(
                    items: viewModel.topicItems,
                    onSelect: { item in
                        coordinator?.insertTopic(item)
                        viewModel.dismissSuggestionPanel()
                    },
                    onDismiss: { viewModel.dismissSuggestionPanel() }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
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
    func insertMention(_ item: MentionItem) {
        guard let textView = textView else { return }
        let triggerLocation = viewModel.getTriggerLocation()
        let currentLocation = textView.selectedRange.location
        let rangeToReplace = NSRange(location: triggerLocation, length: max(0, currentLocation - triggerLocation))
        
        let token = viewModel.createMentionToken(item, font: font)
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
    
    @MainActor
    func insertTopic(_ item: TopicItem) {
        guard let textView = textView else { return }
        let triggerLocation = viewModel.getTriggerLocation()
        let currentLocation = textView.selectedRange.location
        let rangeToReplace = NSRange(location: triggerLocation, length: max(0, currentLocation - triggerLocation))
        
        let token = viewModel.createTopicToken(item, font: font)
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
