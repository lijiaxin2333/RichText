import Foundation
import UIKit
import SwiftUI
import YYText

@MainActor
public final class RichTextEditorViewModel: ObservableObject {
    
    @Published public private(set) var content: RichTextContent = RichTextContent()
    @Published public private(set) var activeTrigger: RichTextTrigger?
    @Published public private(set) var suggestionItems: [any SuggestionItem] = []
    @Published public private(set) var searchKeyword: String = ""
    @Published public internal(set) var pendingAttributedText: NSAttributedString?
    @Published public var isEditable: Bool = true

    /// 点击富文本 token（例如 @提及、#话题#）的回调。
    /// - Note: 只有在 token 的 attributed string 上设置了点击高亮（YYTextHighlight）时才会触发。
    public var onTokenTap: ((RichTextItem) -> Void)?

    /// 统一处理 token 点击：若对应 type 配置了 `RichTextTokenConfig.onTap`，则优先走该回调；
    /// 否则回退到 `onTokenTap`（全局回调）。
    public func handleTokenTap(item: RichTextItem) {
        if let config = configuration.tokenConfig(for: item.type),
           let onTap = config.onTap {
            let context = buildRenderContext(for: item, config: config)
            onTap(context)
            return
        }
        onTokenTap?(item)
    }
    
    private var triggerLocation: Int = 0
    
    private let configuration: RichTextConfiguration
    private var defaultFont: UIFont = .systemFont(ofSize: 16)
    
    public init(configuration: RichTextConfiguration) {
        self.configuration = configuration
    }
    
    public convenience init(factory: SuggestionProviderFactory) {
        self.init(configuration: .defaultConfiguration(factory: factory))
    }
    
    public func getTriggerLocation() -> Int {
        triggerLocation
    }
    
    public func getConfiguration() -> RichTextConfiguration {
        configuration
    }
    
    public func setFont(_ font: UIFont) {
        defaultFont = font
    }
    
    public func setContent(_ content: RichTextContent) {
        let attributedText = buildAttributedText(from: content)
        pendingAttributedText = attributedText
        self.content = content
    }
    
    public func clearContent() {
        pendingAttributedText = NSAttributedString()
        content = RichTextContent()
    }
    
    public func clearPendingText() {
        pendingAttributedText = nil
    }
    
    public func shouldChangeText(in range: NSRange, replacementText text: String, currentText: NSAttributedString) -> Bool {
        if let trigger = configuration.trigger(for: text) {
            triggerLocation = range.location
            activeTrigger = trigger
            searchKeyword = ""
            Task { await fetchSuggestions(trigger: trigger, keyword: "") }
            return true
        }
        
        if activeTrigger != nil {
            if text == " " || text == "\n" {
                dismissSuggestionPanel()
            } else if text.isEmpty && range.location <= triggerLocation {
                dismissSuggestionPanel()
            } else {
                updateSearchKeyword(range: range, replacementText: text, currentText: currentText)
            }
        }
        
        return true
    }
    
    public func textDidChange(_ attributedText: NSAttributedString) {
        parseContent(from: attributedText)
    }
    
    public func dismissSuggestionPanel() {
        activeTrigger = nil
        suggestionItems = []
        searchKeyword = ""
    }
    
    public func createToken(for item: any SuggestionItem, trigger: RichTextTrigger, font: UIFont) -> NSAttributedString {
        let richItem = buildRichTextItem(from: item, trigger: trigger)
        return makeTokenAttributedString(item: richItem, tokenColor: trigger.tokenColor, font: font)
    }
    
    private func buildAttributedText(from content: RichTextContent) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for item in content.items {
            if item.isText {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: defaultFont,
                    .foregroundColor: UIColor.label
                ]
                result.append(NSAttributedString(string: item.displayText, attributes: attrs))
            } else {
                let trigger = configuration.allTriggers.first { $0.tokenType == item.type }
                let tokenColor = trigger?.tokenColor ?? UIColor.systemBlue
                
                let tokenAttrStr = makeTokenAttributedString(item: item, tokenColor: tokenColor, font: defaultFont)
                
                result.append(tokenAttrStr)
                
                let spaceAttrs: [NSAttributedString.Key: Any] = [
                    .font: defaultFont,
                    .foregroundColor: UIColor.label
                ]
                result.append(NSAttributedString(string: " ", attributes: spaceAttrs))
            }
        }
        
        return result
    }
    
    private func updateSearchKeyword(range: NSRange, replacementText text: String, currentText: NSAttributedString) {
        let origin = currentText.string as NSString
        let mutable = NSMutableString(string: origin)
        mutable.replaceCharacters(in: range, with: text)
        
        let start = min(triggerLocation + 1, mutable.length)
        let cursor = min(range.location + (text as NSString).length, mutable.length)
        if cursor <= start {
            searchKeyword = ""
        } else {
            let sub = mutable.substring(with: NSRange(location: start, length: cursor - start))
            if let stop = sub.firstIndex(where: { $0 == " " || $0 == "\n" || $0 == "\t" }) {
                searchKeyword = String(sub[..<stop])
            } else {
                searchKeyword = sub
            }
        }
        
        if let trigger = activeTrigger {
            Task { await fetchSuggestions(trigger: trigger, keyword: searchKeyword) }
        }
    }
    
    private func fetchSuggestions(trigger: RichTextTrigger, keyword: String) async {
        suggestionItems = await trigger.dataProvider.fetchSuggestions(keyword: keyword)
    }
    
    private func parseContent(from attributedText: NSAttributedString) {
        var items: [RichTextItem] = []
        var currentText = ""
        
        attributedText.enumerateAttributes(in: NSRange(location: 0, length: attributedText.length)) { attrs, range, _ in
            if let itemType = attrs[.richTextItemType] as? String,
               let itemId = attrs[.richTextItemId] as? String {
                if !currentText.isEmpty {
                    items.append(.text(currentText))
                    currentText = ""
                }
                let rangeText = (attributedText.string as NSString).substring(with: range)
                let storedText = attrs[.richTextItemDisplayText] as? String
                let displayText = rangeText == "\u{FFFC}" ? (storedText ?? "") : rangeText
                items.append(RichTextItem(type: itemType, displayText: displayText, data: itemId))
            } else {
                let text = (attributedText.string as NSString).substring(with: range)
                currentText += text
            }
        }
        
        if !currentText.isEmpty {
            items.append(.text(currentText))
        }
        
        content = RichTextContent(items: items)
    }
    
    private func buildRichTextItem(from suggestion: any SuggestionItem, trigger: RichTextTrigger) -> RichTextItem {
        if let config = configuration.tokenConfig(for: trigger.tokenType) {
            return config.dataBuilder(suggestion)
        }
        let text = trigger.formatTokenText(item: suggestion)
        return RichTextItem(type: trigger.tokenType, displayText: text, data: suggestion.id)
    }
    
    private func makeTokenAttributedString(item: RichTextItem, tokenColor: UIColor, font: UIFont) -> NSMutableAttributedString {
        let tapAction: YYTextAction = { [weak self] _, _, _, _ in
            self?.handleTokenTap(item: item)
        }
        let highlightBackground = UIColor.systemGray.withAlphaComponent(0.18)

        if let config = configuration.tokenConfig(for: item.type),
           let viewBuilder = config.viewBuilder,
           let tokenView = viewBuilder(buildRenderContext(for: item, config: config), font) {
            let hostingView = RichTextTokenHostingView(rootView: tokenView.view, preferredSize: tokenView.size, font: font)
            let attachmentSize = hostingView.intrinsicContentSize
            let attachment = NSAttributedString.yy_attachmentString(
                withContent: hostingView,
                contentMode: .center,
                attachmentSize: attachmentSize,
                alignTo: font,
                alignment: .center
            )
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .richTextItemType: item.type,
                .richTextItemId: item.data,
                .richTextItemDisplayText: item.displayText
            ]
            attachment.addAttributes(attrs, range: NSRange(location: 0, length: attachment.length))
            attachment.yy_setTextBinding(YYTextBinding(deleteConfirm: true), range: NSRange(location: 0, length: attachment.length))
            attachment.yy_setTextHighlight(
                NSRange(location: 0, length: attachment.length),
                color: nil,
                backgroundColor: highlightBackground,
                tapAction: tapAction
            )
            return attachment
        }
        
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: tokenColor,
            .font: font,
            .richTextItemType: item.type,
            .richTextItemId: item.data,
            .richTextItemDisplayText: item.displayText
        ]
        let result = NSMutableAttributedString(string: item.displayText, attributes: attrs)
        result.yy_setTextBinding(YYTextBinding(deleteConfirm: true), range: NSRange(location: 0, length: result.length))
        result.yy_setTextHighlight(
            NSRange(location: 0, length: result.length),
            color: nil,
            backgroundColor: highlightBackground,
            tapAction: tapAction
        )
        return result
    }
    
    private func buildRenderContext(for item: RichTextItem, config: RichTextTokenConfig) -> RichTextTokenRenderContext {
        let payload = (config.payloadDecoder ?? RichTextTokenConfig.defaultPayloadDecoder)(item.data)
        return RichTextTokenRenderContext(item: item, payload: payload)
    }
}

final class RichTextTokenHostingView: UIView {
    private let hostingController: UIHostingController<AnyView>
    private let intrinsicSize: CGSize
    
    init(rootView: AnyView, preferredSize: CGSize?, font: UIFont) {
        hostingController = UIHostingController(rootView: rootView)
        
        let measured = RichTextTokenHostingView.measureSize(hostingController: hostingController, font: font)
        let finalSize = CGSize(
            width: max(preferredSize?.width ?? measured.width, font.lineHeight),
            height: max(preferredSize?.height ?? measured.height, font.lineHeight)
        )
        intrinsicSize = finalSize
        
        super.init(frame: CGRect(origin: .zero, size: finalSize))
        isUserInteractionEnabled = false
        backgroundColor = .clear
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(hostingController.view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        intrinsicSize
    }
    
    private static func measureSize(hostingController: UIHostingController<AnyView>, font: UIFont) -> CGSize {
        let target = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let measured = hostingController.sizeThatFits(in: target)
        if measured == .zero || measured.width.isNaN || measured.height.isNaN {
            return CGSize(width: font.lineHeight * 2, height: font.lineHeight * 1.2)
        }
        return measured
    }
}

public extension NSAttributedString.Key {
    static let richTextItemType = NSAttributedString.Key("richTextItemType")
    static let richTextItemId = NSAttributedString.Key("richTextItemId")
    static let richTextItemDisplayText = NSAttributedString.Key("richTextItemDisplayText")
}
