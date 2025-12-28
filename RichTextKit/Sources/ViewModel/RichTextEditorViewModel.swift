import Foundation
import UIKit
import YYText

@MainActor
public final class RichTextEditorViewModel: ObservableObject {
    
    @Published public private(set) var content: RichTextContent = RichTextContent()
    @Published public private(set) var activeTrigger: RichTextTrigger?
    @Published public private(set) var suggestionItems: [any SuggestionItem] = []
    @Published public private(set) var searchKeyword: String = ""
    @Published public internal(set) var pendingAttributedText: NSAttributedString?
    
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
        let text = trigger.formatTokenText(item: item)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: trigger.tokenColor,
            .font: font,
            .richTextItemType: trigger.tokenType,
            .richTextItemId: item.id
        ]
        return NSAttributedString(string: text, attributes: attributes)
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
                
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: defaultFont,
                    .foregroundColor: tokenColor,
                    .richTextItemType: item.type,
                    .richTextItemId: item.data
                ]
                let tokenAttrStr = NSMutableAttributedString(string: item.displayText, attributes: attrs)
                
                let binding = YYTextBinding(deleteConfirm: true)
                tokenAttrStr.yy_setTextBinding(binding, range: NSRange(location: 0, length: tokenAttrStr.length))
                
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
                let displayText = (attributedText.string as NSString).substring(with: range)
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
}

public extension NSAttributedString.Key {
    static let richTextItemType = NSAttributedString.Key("richTextItemType")
    static let richTextItemId = NSAttributedString.Key("richTextItemId")
}
