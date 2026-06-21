import SwiftUI

/// Selects a block kind for a custom renderer registered via `.markdownBlockRenderer(_:_:)`.
/// Mirrors `BlockKind` without its associated values, so a host can target a category of block
/// (e.g. every callout) regardless of the specific node.
public enum MarkdownBlockKind: Hashable, Sendable {
    case heading, paragraph, blockQuote, thematicBreak, codeBlock, mermaid
    case mathBlock, list, table, htmlBlock, footnoteDefinition, callout
}

public extension BlockKind {
    /// The renderer-selector category for this block.
    var rendererKind: MarkdownBlockKind {
        switch self {
        case .heading: return .heading
        case .paragraph: return .paragraph
        case .blockQuote: return .blockQuote
        case .thematicBreak: return .thematicBreak
        case .codeBlock: return .codeBlock
        case .mermaid: return .mermaid
        case .mathBlock: return .mathBlock
        case .list: return .list
        case .table: return .table
        case .htmlBlock: return .htmlBlock
        case .footnoteDefinition: return .footnoteDefinition
        case .callout: return .callout
        }
    }
}

/// A host-registered view builder for a block: given the node and the resolved theme, returns the
/// SwiftUI view to render instead of the built-in one.
public typealias MarkdownBlockRenderer = @MainActor (BlockNode, MarkdownTheme) -> AnyView

/// The set of block renderers a host has registered, keyed by block kind.
struct MarkdownBlockRenderers {
    var byKind: [MarkdownBlockKind: MarkdownBlockRenderer] = [:]
}

private struct MarkdownBlockRenderersKey: EnvironmentKey {
    static let defaultValue = MarkdownBlockRenderers()
}

extension EnvironmentValues {
    var markdownBlockRenderers: MarkdownBlockRenderers {
        get { self[MarkdownBlockRenderersKey.self] }
        set { self[MarkdownBlockRenderersKey.self] = newValue }
    }
}

public extension View {
    /// Overrides how a block kind is rendered in `MarkdownView`. The builder receives the
    /// `BlockNode` and the resolved `MarkdownTheme`, and fully replaces the built-in view for
    /// that kind. Other kinds are unaffected. Apply it more than once to override several kinds.
    ///
    /// ```swift
    /// MarkdownView(text)
    ///     .markdownBlockRenderer(.callout) { node, theme in
    ///         AnyView(MyCalloutView(node).tint(theme.accent))
    ///     }
    /// ```
    func markdownBlockRenderer(_ kind: MarkdownBlockKind,
                               _ render: @escaping MarkdownBlockRenderer) -> some View {
        transformEnvironment(\.markdownBlockRenderers) { $0.byKind[kind] = render }
    }
}
