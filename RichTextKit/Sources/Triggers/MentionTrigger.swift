import Foundation
import UIKit

extension MentionItem: SuggestionItem {
    public var displayName: String { name }
}

public struct MentionTrigger: RichTextTrigger {
    public let triggerCharacter: String = "@"
    public let tokenType: String = "mention"
    public let tokenFormat: String = "@{name}"
    public let tokenColor: UIColor
    public let dataProvider: SuggestionDataProvider
    
    public init(dataProvider: SuggestionDataProvider, tokenColor: UIColor = .systemBlue) {
        self.dataProvider = dataProvider
        self.tokenColor = tokenColor
    }
}

public struct MentionDataProviderWrapper: SuggestionDataProvider {
    private let provider: MentionDataProvider
    
    public init(_ provider: MentionDataProvider) {
        self.provider = provider
    }
    
    public func fetchSuggestions(keyword: String) async -> [any SuggestionItem] {
        await provider.fetchMentions(keyword: keyword)
    }
}

