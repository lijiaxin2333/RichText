import Foundation
import SwiftUI
import UIKit

/// 业务侧可为每个 type 配置的数据构建器与 SwiftUI 视图
public struct RichTextTokenConfig {
    public typealias DataBuilder = (_ suggestion: any SuggestionItem) -> RichTextItem
    public typealias PayloadDecoder = (_ data: String) -> [String: String]?
    public typealias ViewBuilder = (_ context: RichTextTokenRenderContext, _ font: UIFont) -> RichTextTokenView?
    
    public let dataBuilder: DataBuilder
    public let payloadDecoder: PayloadDecoder?
    public let viewBuilder: ViewBuilder?
    
    public init(
        dataBuilder: @escaping DataBuilder,
        payloadDecoder: PayloadDecoder? = nil,
        viewBuilder: ViewBuilder? = nil
    ) {
        self.dataBuilder = dataBuilder
        self.payloadDecoder = payloadDecoder
        self.viewBuilder = viewBuilder
    }
    
    /// 默认 JSON 解码器，约定 data 为 JSON 串
    public static func defaultPayloadDecoder(data: String) -> [String: String]? {
        guard let jsonData = data.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: String]
    }
}

/// 传递给 SwiftUI 视图的上下文（包含业务数据 payload）
public struct RichTextTokenRenderContext {
    public let item: RichTextItem
    public let payload: [String: String]?
    
    public init(item: RichTextItem, payload: [String: String]?) {
        self.item = item
        self.payload = payload
    }
}

/// SwiftUI 视图包装
public struct RichTextTokenView {
    public let view: AnyView
    public let size: CGSize?
    
    public init<V: View>(_ view: V, size: CGSize? = nil) {
        self.view = AnyView(view)
        self.size = size
    }
}
