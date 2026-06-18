/// An inline-level node (text, emphasis, links, code, math, …) and the source
/// range it was parsed from.
public struct InlineNode: Sendable, Equatable {
    public let kind: InlineKind
    public let range: SourceRange?

    public init(_ kind: InlineKind, range: SourceRange? = nil) {
        self.kind = kind
        self.range = range
    }
}

/// The kind of an inline node. `indirect` because several cases nest child inlines.
public indirect enum InlineKind: Sendable, Equatable {
    /// Literal text run.
    case text(String)
    /// A soft line break (single newline within a paragraph).
    case softBreak
    /// A hard line break (two trailing spaces or backslash + newline).
    case lineBreak
    /// An inline code span; content is verbatim.
    case code(String)
    /// Emphasis (typically italic).
    case emphasis([InlineNode])
    /// Strong emphasis (typically bold).
    case strong([InlineNode])
    /// GFM strikethrough.
    case strikethrough([InlineNode])
    /// A link with destination, optional title, and child inlines for its text.
    case link(destination: String, title: String?, children: [InlineNode])
    /// An image reference with source, optional title, and alt text.
    case image(source: String, title: String?, alt: String)
    /// An autolinked URL or email.
    case autolink(url: String, isEmail: Bool)
    /// A wiki-style link `[[target|display]]`.
    case wikiLink(target: String, display: String?)
    /// A reference to a footnote definition by label.
    case footnoteReference(label: String)
    /// Inline LaTeX math; body is the raw LaTeX between delimiters.
    case inlineMath(String)
    /// Raw inline HTML.
    case inlineHTML(String)
}
