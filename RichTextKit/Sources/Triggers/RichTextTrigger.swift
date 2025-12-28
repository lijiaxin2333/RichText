import Foundation
import UIKit

public protocol SuggestionItem: Identifiable, Equatable {
    var id: String { get }
    var displayName: String { get }
}

public protocol SuggestionDataProvider {
    func fetchSuggestions(keyword: String) async -> [any SuggestionItem]
}

public protocol RichTextTrigger {
    var triggerCharacter: String { get }
    var tokenType: String { get }
    var tokenFormat: String { get }
    var tokenColor: UIColor { get }
    var dataProvider: SuggestionDataProvider { get }
    
    func formatTokenText(item: any SuggestionItem) -> String
}

public extension RichTextTrigger {
    func formatTokenText(item: any SuggestionItem) -> String {
        tokenFormat.replacingOccurrences(of: "{name}", with: item.displayName)
    }
}

