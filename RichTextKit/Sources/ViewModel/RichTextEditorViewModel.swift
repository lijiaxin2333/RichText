import Foundation
import UIKit

public enum SuggestionPanelType: Equatable {
    case none
    case mention
    case topic
}

@MainActor
public final class RichTextEditorViewModel: ObservableObject {
    
    @Published public private(set) var content: RichTextContent = RichTextContent()
    @Published public private(set) var suggestionPanelType: SuggestionPanelType = .none
    @Published public private(set) var mentionItems: [MentionItem] = []
    @Published public private(set) var topicItems: [TopicItem] = []
    @Published public private(set) var searchKeyword: String = ""
    
    private var triggerLocation: Int = 0
    
    private let factory: SuggestionProviderFactory
    private lazy var mentionProvider: MentionDataProvider = factory.makeMentionProvider()
    private lazy var topicProvider: TopicDataProvider = factory.makeTopicProvider()
    
    public init(factory: SuggestionProviderFactory) {
        self.factory = factory
    }
    
    public func getTriggerLocation() -> Int {
        triggerLocation
    }
    
    public func shouldChangeText(in range: NSRange, replacementText text: String, currentText: NSAttributedString) -> Bool {
        if text == "@" {
            triggerLocation = range.location
            suggestionPanelType = .mention
            searchKeyword = ""
            Task { await fetchMentions(keyword: "") }
            return true
        }
        
        if text == "#" {
            triggerLocation = range.location
            suggestionPanelType = .topic
            searchKeyword = ""
            Task { await fetchTopics(keyword: "") }
            return true
        }
        
        if suggestionPanelType != .none {
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
        suggestionPanelType = .none
        mentionItems = []
        topicItems = []
        searchKeyword = ""
    }
    
    public func createMentionToken(_ item: MentionItem, font: UIFont) -> NSAttributedString {
        let text = "@\(item.name)"
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemBlue,
            .font: font,
            .richTextItemType: RichTextItemType.mention,
            .richTextItemId: item.id
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    public func createTopicToken(_ item: TopicItem, font: UIFont) -> NSAttributedString {
        let text = "#\(item.name)#"
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.systemBlue,
            .font: font,
            .richTextItemType: RichTextItemType.topic,
            .richTextItemId: item.id
        ]
        return NSAttributedString(string: text, attributes: attributes)
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
        
        Task {
            switch suggestionPanelType {
            case .mention:
                await fetchMentions(keyword: searchKeyword)
            case .topic:
                await fetchTopics(keyword: searchKeyword)
            case .none:
                break
            }
        }
    }
    
    private func fetchMentions(keyword: String) async {
        mentionItems = await mentionProvider.fetchMentions(keyword: keyword)
    }
    
    private func fetchTopics(keyword: String) async {
        topicItems = await topicProvider.fetchTopics(keyword: keyword)
    }
    
    private func parseContent(from attributedText: NSAttributedString) {
        var items: [RichTextItem] = []
        var currentText = ""
        
        attributedText.enumerateAttributes(in: NSRange(location: 0, length: attributedText.length)) { attrs, range, _ in
            if let itemType = attrs[.richTextItemType] as? RichTextItemType,
               let itemId = attrs[.richTextItemId] as? String {
                if !currentText.isEmpty {
                    items.append(.text(currentText))
                    currentText = ""
                }
                let displayText = (attributedText.string as NSString).substring(with: range)
                switch itemType {
                case .mention:
                    items.append(RichTextItem(type: .mention, displayText: displayText, data: itemId))
                case .topic:
                    items.append(RichTextItem(type: .topic, displayText: displayText, data: itemId))
                case .text:
                    currentText += displayText
                }
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


