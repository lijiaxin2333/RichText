// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RichTextKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "RichTextKit", targets: ["RichTextKit"]),
        .library(name: "YYText", targets: ["YYText"])
    ],
    targets: [
        .target(
            name: "YYText",
            path: "Sources/YYText",
            sources: [
                "YYLabel.m",
                "YYTextView.m",
                "Component/YYTextContainerView.m",
                "Component/YYTextDebugOption.m",
                "Component/YYTextEffectWindow.m",
                "Component/YYTextInput.m",
                "Component/YYTextKeyboardManager.m",
                "Component/YYTextLayout.m",
                "Component/YYTextLine.m",
                "Component/YYTextMagnifier.m",
                "Component/YYTextSelectionView.m",
                "String/YYTextArchiver.m",
                "String/YYTextAttribute.m",
                "String/YYTextParser.m",
                "String/YYTextRubyAnnotation.m",
                "String/YYTextRunDelegate.m",
                "Utility/NSAttributedString+YYText.m",
                "Utility/NSParagraphStyle+YYText.m",
                "Utility/UIPasteboard+YYText.m",
                "Utility/UIView+YYText.m",
                "Utility/YYTextAsyncLayer.m",
                "Utility/YYTextTransaction.m",
                "Utility/YYTextUtilities.m",
                "Utility/YYTextWeakProxy.m"
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ]
        ),
        .target(
            name: "RichTextKit",
            dependencies: ["YYText"],
            path: "Sources",
            exclude: ["YYText"]
        )
    ]
)
