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
            dependencies: ["SwiftMarkdownEngine"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "MarkdownEngineLatex",
            dependencies: ["SwiftMarkdownEngine"],
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
    ]
)
