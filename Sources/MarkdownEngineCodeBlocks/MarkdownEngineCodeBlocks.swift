import Foundation
import SwiftMarkdownEngine

// Optional bridge product adapting a syntax-highlighting backend to the core
// `SyntaxHighlighter` protocol. The real Highlightr-backed implementation is wired
// in Phase 3 (task 7.3); until then this provides a dependency-free passthrough so
// the product builds and can be adopted.

/// A `SyntaxHighlighter` that returns plain (uncolored) monospaced text.
///
/// > Note: Phase 3 replaces the body with a Highlightr-backed implementation and
/// > adds the Highlightr package dependency to this target only.
public struct PlainCodeHighlighter: SyntaxHighlighter {
    public init() {}

    public func highlight(_ code: String, language: String?) -> AttributedString {
        AttributedString(code)
    }
}
