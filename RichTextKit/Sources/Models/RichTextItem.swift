import Foundation

public enum RichTextItemType: String, Codable, Equatable {
    case text
    case mention
    case topic
}

public struct RichTextItem: Identifiable, Equatable, Codable {
    public let id: String
    public let type: RichTextItemType
    public let displayText: String
    public let data: String
    
    public init(id: String = UUID().uuidString, type: RichTextItemType, displayText: String, data: String) {
        self.id = id
        self.type = type
        self.displayText = displayText
        self.data = data
    }
    
    public static func text(_ content: String) -> RichTextItem {
        RichTextItem(type: .text, displayText: content, data: content)
    }
    
    public static func mention(id: String, name: String) -> RichTextItem {
        RichTextItem(type: .mention, displayText: "@\(name)", data: id)
    }
    
    public static func topic(id: String, name: String) -> RichTextItem {
        RichTextItem(type: .topic, displayText: "#\(name)#", data: id)
    }
}


