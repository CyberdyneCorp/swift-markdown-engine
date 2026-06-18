import SwiftUI

/// Renders a GFM table honoring per-column alignment, scrolling horizontally when
/// wider than the available width.
struct MarkdownTableView: View {
    let table: MarkdownTable

    @Environment(\.resolvedMarkdownTheme) private var theme
    @Environment(\.markdownServices) private var services

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Grid(alignment: .topLeading, horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    ForEach(Array(table.header.enumerated()), id: \.offset) { index, cell in
                        cellView(cell, column: index, isHeader: true)
                    }
                }
                ForEach(Array(table.rows.enumerated()), id: \.offset) { _, row in
                    GridRow {
                        ForEach(Array(row.enumerated()), id: \.offset) { index, cell in
                            cellView(cell, column: index, isHeader: false)
                        }
                    }
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.border))
        }
    }

    private func cellView(_ cell: [InlineNode], column: Int, isHeader: Bool) -> some View {
        let alignment = column < table.alignments.count ? table.alignments[column] : .none
        return InlineRenderer(theme: theme, latexRenderer: services.latexRenderer).text(for: cell)
            .font(isHeader ? theme.bodyFont.bold() : theme.bodyFont)
            .foregroundStyle(theme.textPrimary)
            .multilineTextAlignment(textAlignment(alignment))
            .frame(minWidth: 60, alignment: frameAlignment(alignment))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isHeader ? theme.surface : theme.background)
            .border(theme.border, width: 0.5)
    }

    private func textAlignment(_ a: MarkdownTable.Alignment) -> TextAlignment {
        switch a { case .center: return .center; case .right: return .trailing; default: return .leading }
    }

    private func frameAlignment(_ a: MarkdownTable.Alignment) -> Alignment {
        switch a { case .center: return .center; case .right: return .trailing; default: return .leading }
    }
}
