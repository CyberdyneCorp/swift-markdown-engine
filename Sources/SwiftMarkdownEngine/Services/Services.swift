import Foundation

/// Produces highlighted output for a fenced code block.
public protocol SyntaxHighlighter: Sendable {
    /// Highlights `code` for the given canonical `language`, returning styled text.
    /// Implementations SHOULD return plain attributed text when the language is
    /// unknown rather than failing.
    func highlight(_ code: String, language: String?) -> AttributedString
}

/// Renders LaTeX math to a raster image.
public protocol LatexRenderer: Sendable {
    /// Renders `latex` to PNG data at `pointSize`, in `displayMode` for block math,
    /// using `hexColor` (e.g. `#1B1B1B`) for the glyphs. Returns `nil` if the LaTeX
    /// cannot be parsed.
    func renderToPNG(_ latex: String, displayMode: Bool, pointSize: Double, hexColor: String) -> Data?
}

/// A resolved wiki-link target.
public struct WikiLinkTarget: Sendable, Equatable {
    public let identifier: String
    public let title: String
    public let exists: Bool

    public init(identifier: String, title: String, exists: Bool) {
        self.identifier = identifier
        self.title = title
        self.exists = exists
    }
}

/// Resolves `[[wiki-links]]` and offers completion candidates.
public protocol WikiLinkResolver: Sendable {
    /// Resolves a wiki-link target name to a concrete target, or `nil` if unknown.
    func resolve(_ target: String) -> WikiLinkTarget?
    /// Returns completion candidates matching a partial query.
    func suggestions(matching query: String) -> [WikiLinkTarget]
}

/// Supplies image data for Markdown image references.
public protocol EmbeddedImageProvider: Sendable {
    /// Loads the image bytes for `source` (a URL string or embed name), or `nil`
    /// on failure.
    func imageData(for source: String) async -> Data?
}
