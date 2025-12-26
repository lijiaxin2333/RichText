import Foundation

public struct RichTextContent: Equatable, Codable {
    public var items: [RichTextItem]
    
    public init(items: [RichTextItem] = []) {
        self.items = items
    }
    
    public var plainText: String {
        items.map { $0.displayText }.joined()
    }
    
    public var mentions: [RichTextItem] {
        items.filter { $0.type == .mention }
    }
    
    public var topics: [RichTextItem] {
        items.filter { $0.type == .topic }
    }
}


