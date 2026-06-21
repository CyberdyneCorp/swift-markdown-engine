import SwiftUI
import SwiftMarkdownEngine

/// Routes a single block's Markdown to the right per-type visual editor. Shared by the
/// block-based WYSIWYG editor and the continuous Live editor's tap-to-edit sheet.
struct BlockEditorView: View {
    @Binding var markdown: String
    let theme: MarkdownTheme

    var body: some View {
        switch Self.kind(of: markdown) {
        case .text: TextBlockEditor(markdown: $markdown, theme: theme)
        case .table: TableBlockEditor(markdown: $markdown, theme: theme)
        case .list: ListBlockEditor(markdown: $markdown, theme: theme)
        case .code: CodeBlockEditor(markdown: $markdown, theme: theme)
        case .math: MathBlockEditor(markdown: $markdown, theme: theme)
        case .media: ImageVideoEditor(markdown: $markdown, theme: theme)
        case .flowchart: FlowchartBuilder(markdown: $markdown, theme: theme)
        case .pie: PieChartBuilder(markdown: $markdown, theme: theme)
        case .sequence: SequenceBuilder(markdown: $markdown, theme: theme)
        case .mindmap: MindmapBuilder(markdown: $markdown, theme: theme)
        case .gantt: GanttBuilder(markdown: $markdown, theme: theme)
        case .classDiagram: ClassDiagramBuilder(markdown: $markdown, theme: theme)
        case .stateDiagram: StateDiagramBuilder(markdown: $markdown, theme: theme)
        case .erDiagram: ERDiagramBuilder(markdown: $markdown, theme: theme)
        case .gitGraph: GitGraphBuilder(markdown: $markdown, theme: theme)
        case .journey: JourneyBuilder(markdown: $markdown, theme: theme)
        case .timeline: TimelineBuilder(markdown: $markdown, theme: theme)
        case .diagram: DiagramSourceEditor(markdown: $markdown, theme: theme)
        case .other: sourceEditor
        }
    }

    private var sourceEditor: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Source").font(.caption2.weight(.semibold)).foregroundStyle(theme.textSecondary)
            TextEditor(text: $markdown)
                .font(.system(.callout, design: .monospaced))
                .frame(minHeight: 60)
                .padding(6)
                .background(theme.codeBackground, in: RoundedRectangle(cornerRadius: 6))
                .scrollContentBackground(.hidden)
        }
    }

    enum Kind {
        case text, table, list, code, math, media
        case diagram, flowchart, pie, sequence, mindmap, gantt
        case classDiagram, stateDiagram, erDiagram, gitGraph, journey, timeline, other
    }

    static func kind(of markdown: String) -> Kind {
        guard let kind = MarkdownParser().parse(markdown).blocks.first?.kind else { return .other }
        switch kind {
        case .paragraph(let inlines):
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
            let flat = list.items.allSatisfy { item in
                item.blocks.count == 1 && { if case .paragraph = item.blocks[0].kind { return true } else { return false } }()
            }
            return flat ? .list : .other
        default:
            return .other
        }
    }
}
