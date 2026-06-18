import Foundation

/// Controls optional features, interactivity, and code-block presentation for the
/// renderer and editor.
public struct MarkdownConfiguration: Sendable, Equatable {
    /// Extensions that may be parsed/rendered.
    public struct Extensions: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let math = Extensions(rawValue: 1 << 0)
        public static let mermaid = Extensions(rawValue: 1 << 1)
        public static let footnotes = Extensions(rawValue: 1 << 2)
        public static let wikiLinks = Extensions(rawValue: 1 << 3)
        public static let callouts = Extensions(rawValue: 1 << 4)

        public static let all: Extensions = [.math, .mermaid, .footnotes, .wikiLinks, .callouts]
    }

    public var enabledExtensions: Extensions
    /// When true, rendered task checkboxes are toggleable.
    public var interactiveCheckboxes: Bool
    /// When true, code blocks show line numbers.
    public var showCodeLineNumbers: Bool
    /// When true, code blocks show a copy control.
    public var showCodeCopyButton: Bool

    public init(
        enabledExtensions: Extensions = .all,
        interactiveCheckboxes: Bool = false,
        showCodeLineNumbers: Bool = false,
        showCodeCopyButton: Bool = true
    ) {
        self.enabledExtensions = enabledExtensions
        self.interactiveCheckboxes = interactiveCheckboxes
        self.showCodeLineNumbers = showCodeLineNumbers
        self.showCodeCopyButton = showCodeCopyButton
    }

    public static let `default` = MarkdownConfiguration()

    /// A `MarkdownParser` configured to match these feature toggles.
    public var parser: MarkdownParser {
        MarkdownParser(
            mathEnabled: enabledExtensions.contains(.math),
            wikiLinksEnabled: enabledExtensions.contains(.wikiLinks)
        )
    }
}
