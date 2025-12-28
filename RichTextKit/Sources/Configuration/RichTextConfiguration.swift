import Foundation
import UIKit

public final class RichTextConfiguration {
    
    private var triggers: [String: RichTextTrigger] = [:]
    
    public init() {}
    
    public func register(_ trigger: RichTextTrigger) {
        triggers[trigger.triggerCharacter] = trigger
    }
    
    public func unregister(triggerCharacter: String) {
        triggers.removeValue(forKey: triggerCharacter)
    }
    
    public func trigger(for character: String) -> RichTextTrigger? {
        triggers[character]
    }
    
    public var allTriggers: [RichTextTrigger] {
        Array(triggers.values)
    }
    
    public var triggerCharacters: Set<String> {
        Set(triggers.keys)
    }
    
    public func isTriggerCharacter(_ character: String) -> Bool {
        triggers.keys.contains(character)
    }
}

public extension RichTextConfiguration {
    
    static func defaultConfiguration(factory: SuggestionProviderFactory) -> RichTextConfiguration {
        let config = RichTextConfiguration()
        config.register(MentionTrigger(
            dataProvider: MentionDataProviderWrapper(factory.makeMentionProvider())
        ))
        config.register(TopicTrigger(
            dataProvider: TopicDataProviderWrapper(factory.makeTopicProvider())
        ))
        return config
    }
}

