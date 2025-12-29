import Foundation
import SwiftUI
import UIKit

/// 业务侧可为每个 type 配置的数据构建器与 SwiftUI 视图
public struct RichTextTokenConfig {
    public typealias DataBuilder = (_ suggestion: any SuggestionItem) -> RichTextItem
    public typealias PayloadDecoder = (_ data: String) -> [String: String]?
    public typealias ViewBuilder = (_ context: RichTextTokenRenderContext, _ font: UIFont) -> RichTextTokenView?
    public typealias TapHandler = (_ context: RichTextTokenRenderContext) -> Void
    
    public let dataBuilder: DataBuilder
    public let payloadDecoder: PayloadDecoder?
    public let viewBuilder: ViewBuilder?
    /// 当用户点击该 token 时触发（编辑态与只读态均支持）。
    /// - Note: 若配置了该回调，会优先于 `RichTextEditorView(onTokenTap:)` 的全局回调执行。
    public let onTap: TapHandler?
    
    public init(
        dataBuilder: @escaping DataBuilder,
        payloadDecoder: PayloadDecoder? = nil,
        viewBuilder: ViewBuilder? = nil,
        onTap: TapHandler? = nil
    ) {
        self.dataBuilder = dataBuilder
        self.payloadDecoder = payloadDecoder
        self.viewBuilder = viewBuilder
        self.onTap = onTap
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
