import Foundation
import UIKit

extension TopicItem: SuggestionItem {
    public var displayName: String { name }
}

public struct TopicTrigger: RichTextTrigger {
    public let triggerCharacter: String = "#"
    public let tokenType: String = "topic"
    public let tokenFormat: String = "#{name}#"
    public let tokenColor: UIColor
    public let dataProvider: SuggestionDataProvider
    
    public init(dataProvider: SuggestionDataProvider, tokenColor: UIColor = .systemBlue) {
        self.dataProvider = dataProvider
        self.tokenColor = tokenColor
    }
}

public struct TopicDataProviderWrapper: SuggestionDataProvider {
    private let provider: TopicDataProvider
    
    public init(_ provider: TopicDataProvider) {
        self.provider = provider
    }
    
    public func fetchSuggestions(keyword: String) async -> [any SuggestionItem] {
        await provider.fetchTopics(keyword: keyword)
    }
}

