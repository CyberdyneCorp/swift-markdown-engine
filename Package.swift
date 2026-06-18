// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "swift-markdown-engine",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
    ],
    products: [
        // Core: parser, document model, SwiftUI renderer, Mermaid, theming, services.
        // Zero external dependencies.
        .library(name: "SwiftMarkdownEngine", targets: ["SwiftMarkdownEngine"]),

        // TextKit 2 based editor (iOS/macOS).
        .library(name: "MarkdownEditor", targets: ["MarkdownEditor"]),

        // Optional bridges — only pulled in when a consumer depends on them.
        .library(name: "MarkdownEngineCodeBlocks", targets: ["MarkdownEngineCodeBlocks"]),
        .library(name: "MarkdownEngineLatex", targets: ["MarkdownEngineLatex"]),
    ],
    dependencies: [
        // Used only by the optional bridge targets; the core stays dependency-free.
        .package(url: "https://github.com/raspu/Highlightr", from: "2.3.0"),
        .package(url: "https://github.com/mgriebling/SwiftMath", from: "1.7.3"),
    ],
    targets: [
        .target(
            name: "SwiftMarkdownEngine",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "MarkdownEditor",
            dependencies: ["SwiftMarkdownEngine"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "MarkdownEngineCodeBlocks",
            dependencies: [
                "SwiftMarkdownEngine",
                .product(name: "Highlightr", package: "Highlightr"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "MarkdownEngineLatex",
            dependencies: [
                "SwiftMarkdownEngine",
                .product(name: "SwiftMath", package: "SwiftMath"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "SwiftMarkdownEngineTests",
            dependencies: ["SwiftMarkdownEngine"],
            resources: [.copy("Fixtures")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "MarkdownEditorTests",
            dependencies: ["MarkdownEditor"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "MarkdownBridgesTests",
            dependencies: ["MarkdownEngineCodeBlocks", "MarkdownEngineLatex", "SwiftMarkdownEngine"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
