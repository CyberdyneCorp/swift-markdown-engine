import SwiftUI
import SwiftMarkdownEngine

/// Visual grid editor for a GFM table block: edit cells, add/remove rows and columns, and set
/// per-column alignment — no Markdown pipes shown. Rebuilds the table's Markdown via the engine
/// serializer (`BlockNode.markdown()`) on every change.
struct TableBlockEditor: View {
    @Binding var markdown: String
    let theme: MarkdownTheme

    @State private var headers: [String] = []
    @State private var rows: [[String]] = []
    @State private var alignments: [MarkdownTable.Alignment] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                Grid(alignment: .leading, horizontalSpacing: 6, verticalSpacing: 6) {
                    GridRow {
                        ForEach(headers.indices, id: \.self) { c in
                            headerCell(c)
                        }
                        Color.clear.frame(width: 1, height: 1)
                    }
                    ForEach(rows.indices, id: \.self) { r in
                        GridRow {
                            ForEach(columnRange, id: \.self) { c in
                                cellField(text: cellBinding(r, c), placeholder: "cell")
                            }
                            iconButton("trash", "Delete row") { removeRow(r) }
                        }
                    }
                }
                .padding(4)
            }

            HStack(spacing: 16) {
                Button { addRow() } label: { Label("Row", systemImage: "plus") }
                Button { addColumn() } label: { Label("Column", systemImage: "plus") }
                Spacer()
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(theme.accent)
            .buttonStyle(.plain)
        }
        .onAppear(perform: decompose)
        .onChange(of: headers) { _ in recompose() }
        .onChange(of: rows) { _ in recompose() }
        .onChange(of: alignments) { _ in recompose() }
    }

    private var columnRange: Range<Int> { 0..<headers.count }

    // MARK: - Cells

    private func headerCell(_ c: Int) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                alignmentMenu(c)
                iconButton("xmark.circle", "Delete column") { removeColumn(c) }
                    .disabled(headers.count <= 1)
            }
            cellField(text: headerBinding(c), placeholder: "header").fontWeight(.semibold)
        }
    }

    private func cellField(text: Binding<String>, placeholder: String) -> some View {
        TextField(placeholder, text: text)
            .textInputAutocapitalization(.never)
            .frame(width: 120)
            .padding(6)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 6))
    }

    private func alignmentMenu(_ c: Int) -> some View {
        Menu {
            picker("Default", .none, c)
            picker("Left", .left, c)
            picker("Center", .center, c)
            picker("Right", .right, c)
        } label: {
            Image(systemName: alignmentIcon(alignments[safe: c] ?? .none))
                .foregroundStyle(theme.accent)
        }
    }

    private func picker(_ label: String, _ value: MarkdownTable.Alignment, _ c: Int) -> some View {
        Button(label) { if alignments.indices.contains(c) { alignments[c] = value } }
    }

    private func alignmentIcon(_ a: MarkdownTable.Alignment) -> String {
        switch a {
        case .none, .left: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .right: return "text.alignright"
        }
    }

    private func iconButton(_ system: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: system) }
            .buttonStyle(.plain)
            .foregroundStyle(theme.textSecondary)
            .accessibilityLabel(label)
    }

    // MARK: - Bindings into the grid

    private func headerBinding(_ c: Int) -> Binding<String> {
        Binding(get: { headers[safe: c] ?? "" },
                set: { if headers.indices.contains(c) { headers[c] = $0 } })
    }

    private func cellBinding(_ r: Int, _ c: Int) -> Binding<String> {
        Binding(get: { rows[safe: r]?[safe: c] ?? "" },
                set: { if rows.indices.contains(r), rows[r].indices.contains(c) { rows[r][c] = $0 } })
    }

    // MARK: - Structural edits

    private func addColumn() {
        headers.append("")
        alignments.append(.none)
        for i in rows.indices { rows[i].append("") }
    }

    private func removeColumn(_ c: Int) {
        guard headers.indices.contains(c), headers.count > 1 else { return }
        headers.remove(at: c)
        if alignments.indices.contains(c) { alignments.remove(at: c) }
        for i in rows.indices where rows[i].indices.contains(c) { rows[i].remove(at: c) }
    }

    private func addRow() { rows.append(Array(repeating: "", count: headers.count)) }
    private func removeRow(_ r: Int) { guard rows.indices.contains(r) else { return }; rows.remove(at: r) }

    // MARK: - Markdown <-> grid

    private func decompose() {
        guard case .table(let t)? = MarkdownParser().parse(markdown).blocks.first?.kind else { return }
        headers = t.header.map(Self.cellString)
        rows = t.rows.map { $0.map(Self.cellString) }
        alignments = t.alignments
        normalizeShape()
    }

    private func recompose() {
        normalizeShape()
        let table = MarkdownTable(
            alignments: alignments,
            header: headers.map(Self.cellInlines),
            rows: rows.map { $0.map(Self.cellInlines) }
        )
        markdown = BlockNode(.table(table)).markdown()
    }

    /// Keeps alignments and every row at the header's column count.
    private func normalizeShape() {
        let cols = headers.count
        while alignments.count < cols { alignments.append(.none) }
        if alignments.count > cols { alignments.removeLast(alignments.count - cols) }
        for i in rows.indices {
            while rows[i].count < cols { rows[i].append("") }
            if rows[i].count > cols { rows[i].removeLast(rows[i].count - cols) }
        }
    }

    private static func cellString(_ inlines: [InlineNode]) -> String {
        inlines.map { $0.markdown() }.joined()
    }

    private static func cellInlines(_ s: String) -> [InlineNode] {
        guard case .paragraph(let nodes)? = MarkdownParser().parse(s).blocks.first?.kind else {
            return s.isEmpty ? [] : [InlineNode(.text(s))]
        }
        return nodes
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
