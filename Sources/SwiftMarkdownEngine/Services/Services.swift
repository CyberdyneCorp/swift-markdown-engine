import Foundation
import SwiftUI

/// Supplies an inline player view for a provider video (e.g. YouTube/Vimeo). The core
/// never embeds a WebView itself — a host app injects an implementation (typically
/// WebKit-backed) so provider videos can play inline while the core stays WebView-free.
/// When no embedder is provided, provider videos open externally instead.
public protocol VideoEmbedder: Sendable {
    /// Returns a view that plays the provider video at `url` inline, or `nil` to fall
    /// back to opening the URL externally. Called on the main actor.
    @MainActor func embedView(for url: URL) -> AnyView?
}

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
