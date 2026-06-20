import SwiftUI
import SwiftMarkdownEngine

/// One editable block: a stable id plus its Markdown fragment. The fragment is the unit the
/// editor renders (via `MarkdownView`) and, in later phases, edits with per-type visual editors.
struct EditableBlock: Identifiable, Equatable {
    let id = UUID()
    var markdown: String
}

/// Phase-1 WYSIWYG editor framework: renders the document as a stack of rendered blocks with
/// selection, insert/delete/reorder, and an interim per-block source editor (replaced by
/// visual editors per type in later phases). Markdown stays the source of truth — structural
/// and content edits are serialized back to the shared `text` binding.
struct WysiwygEditorView: View {
    @Binding var text: String
    let theme: MarkdownTheme
    let services: MarkdownServices

    @State private var blocks: [EditableBlock] = []
    @State private var selected: UUID?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                if blocks.isEmpty { emptyState }
                ForEach($blocks) { $block in
                    blockRow($block)
                }
                insertButton(label: "Add block", at: blocks.count)
                    .padding(.top, 4)
            }
            .padding(12)
            .frame(maxWidth: theme.readingWidth ?? .infinity)
            .frame(maxWidth: .infinity)
        }
        .background(theme.background)
        .onAppear(perform: syncFromText)   // re-sync each time Edit mode is entered
    }

    // MARK: - Rows

    @ViewBuilder
    private func blockRow(_ block: Binding<EditableBlock>) -> some View {
        let isSelected = selected == block.id

        VStack(alignment: .leading, spacing: 8) {
            MarkdownView(block.wrappedValue.markdown)
                .markdownTheme(theme)
                .markdownServices(services)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { selected = isSelected ? nil : block.id }

            if isSelected {
                controls(for: block)
                sourceEditor(for: block)   // interim editor — visual per-type editors come next
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? theme.accent.opacity(0.08) : theme.surface.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? theme.accent.opacity(0.6) : .clear, lineWidth: 1.5)
        )
    }

    private func controls(for block: Binding<EditableBlock>) -> some View {
        HStack(spacing: 14) {
            iconButton("arrow.up", "Move up") { move(block.id, by: -1) }
                .disabled(index(of: block.id) == 0)
            iconButton("arrow.down", "Move down") { move(block.id, by: 1) }
                .disabled(index(of: block.id) == blocks.count - 1)
            iconButton("trash", "Delete", role: .destructive) { delete(block.id) }
            Spacer()
            insertButton(label: "Insert below", at: (index(of: block.id) ?? blocks.count - 1) + 1)
        }
        .font(.system(size: 15, weight: .medium))
    }

    private func sourceEditor(for block: Binding<EditableBlock>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Source")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(theme.textSecondary)
            TextEditor(text: Binding(
                get: { block.wrappedValue.markdown },
                set: { block.wrappedValue.markdown = $0; writeBack() }
            ))
            .font(.system(.callout, design: .monospaced))
            .frame(minHeight: 60)
            .padding(6)
            .background(theme.codeBackground, in: RoundedRectangle(cornerRadius: 6))
            .scrollContentBackground(.hidden)
        }
    }

    private var emptyState: some View {
        Text("Empty document — tap **Add block** to start.")
            .foregroundStyle(theme.textSecondary)
            .padding(.vertical, 24)
    }

    private func insertButton(label: String, at offset: Int) -> some View {
        Menu {
            Button("Paragraph") { insert("New paragraph.", at: offset) }
            Button("Heading") { insert("## Heading", at: offset) }
            Button("Bulleted list") { insert("- Item", at: offset) }
            Button("Quote") { insert("> Quote", at: offset) }
            Button("Code") { insert("```swift\ncode\n```", at: offset) }
            Button("Table") { insert("| A | B |\n| --- | --- |\n| 1 | 2 |", at: offset) }
            Button("Divider") { insert("---", at: offset) }
        } label: {
            Label(label, systemImage: "plus.circle.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(theme.accent)
        }
    }

    private func iconButton(_ system: String, _ label: String, role: ButtonRole? = nil,
                            action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) { Image(systemName: system) }
            .buttonStyle(.plain)
            .foregroundStyle(role == .destructive ? .red : theme.accent)
            .accessibilityLabel(label)
    }

    // MARK: - Mutations

    private func index(of id: UUID) -> Int? { blocks.firstIndex { $0.id == id } }

    private func insert(_ markdown: String, at offset: Int) {
        let new = EditableBlock(markdown: markdown)
        blocks.insert(new, at: min(max(0, offset), blocks.count))
        selected = new.id
        writeBack()
    }

    private func delete(_ id: UUID) {
        blocks.removeAll { $0.id == id }
        if selected == id { selected = nil }
        writeBack()
    }

    private func move(_ id: UUID, by delta: Int) {
        guard let i = index(of: id) else { return }
        let j = i + delta
        guard blocks.indices.contains(j) else { return }
        blocks.swapAt(i, j)
        writeBack()
    }

    // MARK: - Markdown <-> blocks

    private func syncFromText() {
        blocks = MarkdownParser().parse(text).blocks.map { EditableBlock(markdown: $0.markdown()) }
    }

    private func writeBack() {
        text = blocks.map(\.markdown)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n\n") + "\n"
    }
}
