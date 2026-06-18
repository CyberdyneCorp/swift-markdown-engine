/// A container bundling the optional services the engine uses. Any service left
/// `nil` falls back to the engine's safe default behavior (plain code, raw math,
/// plain wiki-links, default image loading).
public struct MarkdownServices: Sendable {
    public var syntaxHighlighter: (any SyntaxHighlighter)?
    public var latexRenderer: (any LatexRenderer)?
    public var wikiLinkResolver: (any WikiLinkResolver)?
    public var imageProvider: (any EmbeddedImageProvider)?

    public init(
        syntaxHighlighter: (any SyntaxHighlighter)? = nil,
        latexRenderer: (any LatexRenderer)? = nil,
        wikiLinkResolver: (any WikiLinkResolver)? = nil,
        imageProvider: (any EmbeddedImageProvider)? = nil
    ) {
        self.syntaxHighlighter = syntaxHighlighter
        self.latexRenderer = latexRenderer
        self.wikiLinkResolver = wikiLinkResolver
        self.imageProvider = imageProvider
    }

    /// Services with no integrations configured; the engine uses defaults.
    public static let `default` = MarkdownServices()
}
