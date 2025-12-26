import Foundation

public protocol MentionDataProvider {
    func fetchMentions(keyword: String) async -> [MentionItem]
}

public protocol TopicDataProvider {
    func fetchTopics(keyword: String) async -> [TopicItem]
}

public protocol SuggestionProviderFactory {
    func makeMentionProvider() -> MentionDataProvider
    func makeTopicProvider() -> TopicDataProvider
}


