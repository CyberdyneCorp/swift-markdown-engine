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
        .accessibilityIdentifier("wysiwygEditor")
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
                editor(for: block)
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

    /// Routes text blocks (paragraph/heading/simple quote) to the visual text editor; every
    /// other block type keeps the interim source editor until its visual editor ships.
    @ViewBuilder
    private func editor(for block: Binding<EditableBlock>) -> some View {
        let boundMarkdown = Binding(
            get: { block.wrappedValue.markdown },
            set: { block.wrappedValue.markdown = $0; writeBack() }
        )
        switch blockKind(block.wrappedValue.markdown) {
        case .text:
            TextBlockEditor(markdown: boundMarkdown, theme: theme)
        case .table:
            TableBlockEditor(markdown: boundMarkdown, theme: theme)
        case .list:
            ListBlockEditor(markdown: boundMarkdown, theme: theme)
        case .code:
            CodeBlockEditor(markdown: boundMarkdown, theme: theme)
        case .math:
            MathBlockEditor(markdown: boundMarkdown, theme: theme)
        case .media:
            ImageVideoEditor(markdown: boundMarkdown, theme: theme)
        case .flowchart:
            FlowchartBuilder(markdown: boundMarkdown, theme: theme)
        case .pie:
            PieChartBuilder(markdown: boundMarkdown, theme: theme)
        case .sequence:
            SequenceBuilder(markdown: boundMarkdown, theme: theme)
        case .mindmap:
            MindmapBuilder(markdown: boundMarkdown, theme: theme)
        case .gantt:
            GanttBuilder(markdown: boundMarkdown, theme: theme)
        case .classDiagram:
            ClassDiagramBuilder(markdown: boundMarkdown, theme: theme)
        case .stateDiagram:
            StateDiagramBuilder(markdown: boundMarkdown, theme: theme)
        case .erDiagram:
            ERDiagramBuilder(markdown: boundMarkdown, theme: theme)
        case .gitGraph:
            GitGraphBuilder(markdown: boundMarkdown, theme: theme)
        case .journey:
            JourneyBuilder(markdown: boundMarkdown, theme: theme)
        case .timeline:
            TimelineBuilder(markdown: boundMarkdown, theme: theme)
        case .diagram:
            DiagramSourceEditor(markdown: boundMarkdown, theme: theme)
        case .other:
            sourceEditor(for: block)
        }
    }

    private enum EditorKind {
        case text, table, list, code, math, media
        case diagram, flowchart, pie, sequence, mindmap, gantt
        case classDiagram, stateDiagram, erDiagram, gitGraph, journey, timeline, other
    }

    private func blockKind(_ markdown: String) -> EditorKind {
        guard let kind = MarkdownParser().parse(markdown).blocks.first?.kind else { return .other }
        switch kind {
        case .paragraph(let inlines):
            // A paragraph that is solely an image / linked image is media, not prose.
            if inlines.count == 1 {
                if case .image = inlines[0].kind { return .media }
                if case .link(_, _, let children) = inlines[0].kind,
                   children.count == 1, case .image = children[0].kind { return .media }
            }
            return .text
        case .heading:
            return .text
        case .blockQuote(let blocks):
            if blocks.count == 1, case .paragraph = blocks[0].kind { return .text }
            return .other
        case .table:
            return .table
        case .codeBlock:
            return .code
        case .mathBlock:
            return .math
        case .mermaid(let source):
            let header = source.split(separator: "\n").first
                .map { $0.trimmingCharacters(in: .whitespaces).lowercased() } ?? ""
            if header.hasPrefix("flowchart") || header.hasPrefix("graph") { return .flowchart }
            if header.hasPrefix("pie") { return .pie }
            if header.hasPrefix("sequencediagram") { return .sequence }
            if header.hasPrefix("mindmap") { return .mindmap }
            if header.hasPrefix("gantt") { return .gantt }
            if header.hasPrefix("classdiagram") { return .classDiagram }
            if header.hasPrefix("statediagram") { return .stateDiagram }
            if header.hasPrefix("erdiagram") { return .erDiagram }
            if header.hasPrefix("gitgraph") { return .gitGraph }
            if header.hasPrefix("journey") { return .journey }
            if header.hasPrefix("timeline") { return .timeline }
            return .diagram
        case .list(let list):
            // Only flat lists (each item a single paragraph) get the visual editor; nested
            // lists keep the source editor.
            let flat = list.items.allSatisfy { item in
                item.blocks.count == 1 && { if case .paragraph = item.blocks[0].kind { return true } else { return false } }()
            }
            return flat ? .list : .other
        default:
            return .other
        }
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
            Button("Flowchart") { insert("```mermaid\nflowchart LR\n  A[Start] --> B[End]\n```", at: offset) }
            Button("Pie chart") { insert("```mermaid\npie title Chart\n  \"A\" : 1\n```", at: offset) }
            Button("Sequence") { insert("```mermaid\nsequenceDiagram\n  participant A\n  participant B\n  A->>B: Hello\n```", at: offset) }
            Button("Mindmap") { insert("```mermaid\nmindmap\n  root((Topic))\n    Idea\n```", at: offset) }
            Button("Gantt") { insert("```mermaid\ngantt\n  title Plan\n  section Phase\n  Task : 3d\n```", at: offset) }
            Button("Class diagram") { insert("```mermaid\nclassDiagram\n  class Animal\n  Animal : +int age\n```", at: offset) }
            Button("State diagram") { insert("```mermaid\nstateDiagram-v2\n  [*] --> Idle\n  Idle --> Active\n```", at: offset) }
            Button("ER diagram") { insert("```mermaid\nerDiagram\n  CUSTOMER ||--o{ ORDER : places\n```", at: offset) }
            Button("Git graph") { insert("```mermaid\ngitGraph\n  commit\n  branch dev\n  checkout dev\n  commit\n```", at: offset) }
            Button("Journey") { insert("```mermaid\njourney\n  title My Day\n  section Work\n  Code: 4: Me\n```", at: offset) }
            Button("Timeline") { insert("```mermaid\ntimeline\n  title History\n  2020 : Start\n```", at: offset) }
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
