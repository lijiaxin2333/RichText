import Foundation
import RichTextKit

final class MockSuggestionProviderFactory: SuggestionProviderFactory {
    func makeMentionProvider() -> MentionDataProvider { MockMentionProvider() }
    func makeTopicProvider() -> TopicDataProvider { MockTopicProvider() }
}

final class MockMentionProvider: MentionDataProvider {
    private let items: [MentionItem] = [
        MentionItem(id: "1", name: "张三"),
        MentionItem(id: "2", name: "李四"),
        MentionItem(id: "3", name: "王五"),
        MentionItem(id: "4", name: "赵六"),
        MentionItem(id: "5", name: "钱七"),
        MentionItem(id: "6", name: "孙八")
    ]
    
    func fetchMentions(keyword: String) async -> [MentionItem] {
        if keyword.isEmpty { return items }
        return items.filter { $0.name.contains(keyword) }
    }
}

final class MockTopicProvider: TopicDataProvider {
    private let items: [TopicItem] = [
        TopicItem(id: "1", name: "热门话题", count: 12580),
        TopicItem(id: "2", name: "今日推荐", count: 8964),
        TopicItem(id: "3", name: "科技前沿", count: 6543),
        TopicItem(id: "4", name: "生活日常", count: 5432)
    ]
    
    func fetchTopics(keyword: String) async -> [TopicItem] {
        if keyword.isEmpty { return items }
        return items.filter { $0.name.contains(keyword) }
    }
}


