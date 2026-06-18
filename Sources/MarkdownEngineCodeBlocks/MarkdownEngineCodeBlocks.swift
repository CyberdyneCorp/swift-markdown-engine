import Foundation
import SwiftMarkdownEngine
import Highlightr

/// A `SyntaxHighlighter` backed by Highlightr (highlight.js via JavaScriptCore).
///
/// The Highlightr instance is created lazily and reused behind a lock, since
/// constructing a JavaScript context per call would be expensive. Falls back to
/// plain text when highlighting is unavailable.
public struct HighlightrSyntaxHighlighter: SyntaxHighlighter {
    private let box = HighlightrBox()
    private let theme: String

    /// Creates the highlighter with a highlight.js theme name (e.g. `atom-one-dark`,
    /// `xcode`, `github`).
    public init(theme: String = "atom-one-dark") {
        self.theme = theme
    }

    public func highlight(_ code: String, language: String?) -> AttributedString {
        if let ns = box.highlight(code, language: CodeLanguage.canonical(language), theme: theme) {
            return AttributedString(ns)
        }
        return AttributedString(code)
    }
}

/// Thread-safe holder for a reused Highlightr instance.
private final class HighlightrBox: @unchecked Sendable {
    private let lock = NSLock()
    private var highlightr: Highlightr?
    private var appliedTheme: String?

    func highlight(_ code: String, language: String?, theme: String) -> NSAttributedString? {
        lock.lock()
        defer { lock.unlock() }
        if highlightr == nil { highlightr = Highlightr() }
        guard let highlightr else { return nil }
        if appliedTheme != theme {
            _ = highlightr.setTheme(to: theme)
            appliedTheme = theme
        }
        return highlightr.highlight(code, as: language, fastRender: true)
    }
}
