import SwiftUI

/// A SwiftUI view that renders Markdown natively (no WebView).
///
/// Construct it from a raw string or a pre-parsed `MarkdownDocument`. Theming,
/// configuration, and services are read from the environment; set them with
/// `.markdownTheme(_:)`, `.markdownConfiguration(_:)`, and `.markdownServices(_:)`.
/// Links are opened through SwiftUI's `openURL` environment action.
public struct MarkdownView: View {
    private enum Content {
        case source(String)
        case document(MarkdownDocument)
    }

    private let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.markdownThemeOverride) private var themeOverride
    @Environment(\.markdownConfiguration) private var configuration

    /// Renders Markdown from a raw string. Parsing happens during rendering.
    public init(_ source: String) {
        self.content = .source(source)
    }

    /// Renders a previously parsed document without re-parsing.
    public init(document: MarkdownDocument) {
        self.content = .document(document)
    }

    private var resolvedTheme: MarkdownTheme {
        themeOverride ?? (colorScheme == .dark ? .dark : .light)
    }

    private var document: MarkdownDocument {
        switch content {
        case .document(let doc): return doc
        case .source(let text): return configuration.parser.parse(text)
        }
    }

    public var body: some View {
        let theme = resolvedTheme
        let doc = document
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: theme.paragraphSpacing) {
                ForEach(Array(doc.blocks.enumerated()), id: \.offset) { _, block in
                    BlockView(block: block)
                }
                footnotes(doc, theme: theme)
            }
            .frame(maxWidth: theme.readingWidth ?? .infinity, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
        .environment(\.resolvedMarkdownTheme, theme)
        .background(theme.background)
    }

    @ViewBuilder
    private func footnotes(_ doc: MarkdownDocument, theme: MarkdownTheme) -> some View {
        if !doc.footnotes.isEmpty {
            Divider().padding(.vertical, 4)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(doc.footnotes.sorted(by: { $0.key < $1.key }), id: \.key) { label, blocks in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(label).").font(.caption).foregroundStyle(theme.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                                BlockView(block: block)
                            }
                        }
                    }
                    .font(.callout)
                }
            }
        }
    }
}
