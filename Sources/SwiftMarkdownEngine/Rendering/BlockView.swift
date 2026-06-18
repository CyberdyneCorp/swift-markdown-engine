import SwiftUI

/// Renders a single block node. Container blocks recurse through `BlockListView`.
struct BlockView: View {
    let block: BlockNode

    @Environment(\.resolvedMarkdownTheme) private var theme

    var body: some View {
        switch block.kind {
        case .heading(let level, let inlines):
            headingView(level: level, inlines: inlines)
        case .paragraph(let inlines):
            inlineText(inlines)
        case .blockQuote(let blocks):
            quoteView(blocks)
        case .thematicBreak:
            Rectangle().fill(theme.border).frame(height: 1).padding(.vertical, 4)
        case .codeBlock(let language, let content):
            CodeBlockView(language: language, code: content)
        case .mermaid(let source):
            MermaidView(source: source)
        case .mathBlock(let body):
            MathBlockView(body)
        case .list(let list):
            MarkdownListView(list: list)
        case .table(let table):
            MarkdownTableView(table: table)
        case .htmlBlock(let html):
            Text(html).font(theme.codeFont).foregroundStyle(theme.textSecondary)
        case .callout(let kind, let title, let blocks):
            CalloutView(kind: kind, title: title, blocks: blocks)
        case .footnoteDefinition:
            EmptyView() // footnote definitions render in the notes section, not inline
        }
    }

    private func headingView(level: Int, inlines: [InlineNode]) -> some View {
        inlineText(inlines)
            .font(theme.headingFont(level))
            .foregroundStyle(theme.textPrimary)
            .accessibilityAddTraits(.isHeader)
            .accessibilityHeading(headingLevel(level))
            .padding(.top, level <= 2 ? 6 : 2)
    }

    private func inlineText(_ inlines: [InlineNode]) -> some View {
        // A paragraph that is solely an image renders the image as a block.
        if inlines.count == 1, case .image(let source, _, let alt) = inlines[0].kind {
            return AnyView(MarkdownImageView(source: source, alt: alt))
        }
        return AnyView(
            Text(InlineRenderer(theme: theme).attributedString(for: inlines))
                .font(theme.bodyFont)
                .foregroundStyle(theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        )
    }

    private func quoteView(_ blocks: [BlockNode]) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2).fill(theme.blockQuoteBar).frame(width: 3)
            VStack(alignment: .leading, spacing: theme.paragraphSpacing) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, child in
                    BlockView(block: child)
                }
            }
        }
        .foregroundStyle(theme.textSecondary)
    }

    private func headingLevel(_ level: Int) -> AccessibilityHeadingLevel {
        switch level {
        case 1: return .h1
        case 2: return .h2
        case 3: return .h3
        case 4: return .h4
        case 5: return .h5
        default: return .h6
        }
    }
}

/// Renders an ordered/unordered/task list, recursing for nested lists.
struct MarkdownListView: View {
    let list: MarkdownList

    @Environment(\.resolvedMarkdownTheme) private var theme
    @Environment(\.markdownConfiguration) private var config
    @Environment(\.markdownTaskToggleHandler) private var toggleHandler

    var body: some View {
        VStack(alignment: .leading, spacing: list.isTight ? 2 : theme.paragraphSpacing) {
            ForEach(Array(list.items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    marker(for: item, index: index)
                    VStack(alignment: .leading, spacing: list.isTight ? 2 : theme.paragraphSpacing) {
                        ForEach(Array(item.blocks.enumerated()), id: \.offset) { _, child in
                            BlockView(block: child)
                        }
                    }
                }
            }
        }
        .padding(.leading, theme.listIndent)
    }

    @ViewBuilder private func marker(for item: ListItem, index: Int) -> some View {
        if let checkbox = item.checkbox {
            checkboxMarker(checkbox, range: nil)
        } else {
            switch list.marker {
            case .bullet:
                Text("•").foregroundStyle(theme.textSecondary)
            case .ordered(let start):
                Text("\(start + index).").foregroundStyle(theme.textSecondary).font(theme.bodyFont)
            }
        }
    }

    @ViewBuilder private func checkboxMarker(_ checkbox: ListItem.Checkbox, range: SourceRange?) -> some View {
        let isChecked = checkbox == .checked
        let symbol = isChecked ? "checkmark.square.fill" : "square"
        if config.interactiveCheckboxes, let handler = toggleHandler {
            Button {
                handler.action(range, !isChecked)
            } label: {
                Image(systemName: symbol).foregroundStyle(isChecked ? theme.accent : theme.textSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isChecked ? "Completed task" : "Incomplete task")
        } else {
            Image(systemName: symbol).foregroundStyle(isChecked ? theme.accent : theme.textSecondary)
        }
    }
}

/// Renders a callout/admonition block.
struct CalloutView: View {
    let kind: CalloutKind
    let title: String?
    let blocks: [BlockNode]

    @Environment(\.resolvedMarkdownTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                Text(title ?? kind.rawValue.capitalized).font(theme.bodyFont.bold())
            }
            .foregroundStyle(theme.accent)
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, child in
                BlockView(block: child)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface)
        .overlay(
            HStack { Rectangle().fill(theme.accent).frame(width: 3); Spacer() }
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var iconName: String {
        switch kind {
        case .note, .info: return "info.circle"
        case .tip, .success: return "lightbulb"
        case .important: return "exclamationmark.circle"
        case .warning, .caution: return "exclamationmark.triangle"
        case .danger: return "flame"
        case .question: return "questionmark.circle"
        case .quote: return "quote.opening"
        }
    }
}
