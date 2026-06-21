import SwiftUI

/// Renders a Mermaid diagram natively (SwiftUI Canvas) when its type is supported,
/// falling back to the diagram source as a labeled code block otherwise. Diagrams
/// that exceed the available width scroll horizontally.
struct MermaidView: View {
    let source: String

    @Environment(\.resolvedMarkdownTheme) private var theme
    @Environment(\.markdownConfiguration) private var configuration

    var body: some View {
        #if os(watchOS)
        // watchOS renders a constrained subset: layout-heavy diagrams degrade to
        // their source so the small screen stays legible and fast.
        CodeBlockView(language: "mermaid", code: source)
        #else
        nativeBody
        #endif
    }

    #if !os(watchOS)
    @ViewBuilder private var nativeBody: some View {
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

    /// In scroll mode, wraps an oversized diagram in a horizontal scroll view. In fit-to-width
    /// mode the diagram scales itself (see `diagramFrame`), so the content passes through.
    @ViewBuilder private func scrollable<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        switch configuration.diagramSizing {
        case .scroll:
            ScrollView(.horizontal, showsIndicators: false) { content().padding(8) }
        case .fitToWidth:
            content().padding(8)
        }
    }
    #endif
}

/// Sizes a fixed-size diagram view. In `.scroll` mode it just applies the natural frame; in
/// `.fitToWidth` mode it scales the diagram down (never up) to fit the available width, keeping
/// the whole diagram visible. The natural size is known at the call site, so the fit is computed
/// synchronously (no preference round-trip) and works inside hosted/measured contexts.
/// Defined for all platforms because the diagram views call it even where Mermaid degrades to
/// source (watchOS) — only `MermaidView`'s own diagram rendering is gated off there.
private struct DiagramFrame: ViewModifier {
    let natural: CGSize
    @Environment(\.markdownConfiguration) private var configuration

    func body(content: Content) -> some View {
        let framed = content.frame(width: natural.width, height: natural.height)
        switch configuration.diagramSizing {
        case .scroll:
            framed
        case .fitToWidth:
            GeometryReader { geo in
                let scale = (natural.width > geo.size.width && natural.width > 0) ? geo.size.width / natural.width : 1
                framed
                    .scaleEffect(scale, anchor: .topLeading)
                    .frame(width: geo.size.width, height: natural.height * scale, alignment: .topLeading)
            }
            .aspectRatio(natural.height > 0 ? natural.width / natural.height : 1, contentMode: .fit)
            .frame(maxWidth: natural.width)   // cap at natural size — never upscale
        }
    }
}

extension View {
    /// Applies a diagram's natural frame, scaling it to fit the available width in fit-to-width mode.
    func diagramFrame(width: CGFloat, height: CGFloat) -> some View {
        modifier(DiagramFrame(natural: CGSize(width: width, height: height)))
    }
}
