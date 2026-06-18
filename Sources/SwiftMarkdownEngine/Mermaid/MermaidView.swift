import SwiftUI

/// Renders a Mermaid diagram natively (SwiftUI Canvas) when its type is supported,
/// falling back to the diagram source as a labeled code block otherwise. Diagrams
/// that exceed the available width scroll horizontally.
struct MermaidView: View {
    let source: String

    @Environment(\.resolvedMarkdownTheme) private var theme

    var body: some View {
        switch MermaidDiagramType.detect(from: source) {
        case .flowchart:
            scrollable { FlowchartView(chart: FlowchartParser.parse(source), theme: theme) }
        case .stateDiagram:
            scrollable { FlowchartView(chart: StateDiagramParser.parse(source), theme: theme) }
        case .classDiagram:
            scrollable { ClassDiagramView(model: ClassDiagramParser.parse(source), theme: theme) }
        case .erDiagram:
            scrollable { ERDiagramView(model: ERDiagramParser.parse(source), theme: theme) }
        case .mindmap:
            scrollable { MindmapView(model: MindmapParser.parse(source), theme: theme) }
        case .sequence:
            scrollable { SequenceDiagramView(model: SequenceParser.parse(source), theme: theme) }
        case .pie:
            PieChartView(model: PieChartParser.parse(source), theme: theme)
                .padding(.vertical, 4)
        case .gantt:
            scrollable { GanttView(model: GanttParser.parse(source), theme: theme) }
        case .gitGraph:
            scrollable { GitGraphView(model: GitGraphParser.parse(source), theme: theme) }
        case .journey:
            scrollable { JourneyView(model: JourneyParser.parse(source), theme: theme) }
        case .timeline:
            scrollable { TimelineView(model: TimelineParser.parse(source), theme: theme) }
        default:
            // Unsupported type: spec-defined fallback to highlighted source.
            CodeBlockView(language: "mermaid", code: source)
        }
    }

    private func scrollable<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            content().padding(8)
        }
    }
}
