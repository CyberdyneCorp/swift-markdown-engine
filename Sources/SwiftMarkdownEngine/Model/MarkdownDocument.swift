/// A fully parsed Markdown document: an immutable, `Sendable` value type safe to
/// pass across concurrency domains.
public struct MarkdownDocument: Sendable, Equatable {
    /// Top-level blocks in document order (frontmatter excluded).
    public let blocks: [BlockNode]
    /// Parsed YAML frontmatter, if the document began with a `---` block.
    public let frontmatter: Frontmatter?
    /// Footnote definitions keyed by label.
    public let footnotes: [String: [BlockNode]]
    /// The original source text the document was parsed from.
    public let source: String

    public init(
        blocks: [BlockNode],
        frontmatter: Frontmatter? = nil,
        footnotes: [String: [BlockNode]] = [:],
        source: String
    ) {
        self.blocks = blocks
        self.frontmatter = frontmatter
        self.footnotes = footnotes
        self.source = source
    }
}

/// YAML frontmatter exposed both as raw text and as flat key/value metadata.
public struct Frontmatter: Sendable, Equatable {
    /// The raw text between the `---` fences (excluding the fences).
    public let raw: String
    /// Top-level scalar key/value pairs parsed from the frontmatter.
    public let values: [String: String]

    public init(raw: String, values: [String: String]) {
        self.raw = raw
        self.values = values
    }
}
