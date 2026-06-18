import Foundation

/// Parses Markdown source (CommonMark + GFM + extensions) into a `MarkdownDocument`.
///
/// The parser is a value type with no shared state, so it is safe to run off the
/// main actor. Parsing never throws or crashes on arbitrary input; unresolved
/// constructs degrade to literal text.
///
/// > Note: Block and inline parsing are implemented incrementally across the
/// > Phase 1 tasks. This entry point currently produces a minimal document and
/// > will be expanded to full CommonMark + GFM conformance.
public struct MarkdownParser: Sendable {
    public init() {}

    /// Parses `source` into an immutable document model.
    public func parse(_ source: String) -> MarkdownDocument {
        // TODO(Phase 1): full CommonMark + GFM + extension parsing (tasks 3.1–3.8).
        // Placeholder: treat the whole input as a single paragraph so the model and
        // public API are exercised end-to-end while block/inline parsing lands.
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let blocks: [BlockNode] = trimmed.isEmpty
            ? []
            : [BlockNode(.paragraph([InlineNode(.text(trimmed))]))]
        return MarkdownDocument(blocks: blocks, source: source)
    }
}
