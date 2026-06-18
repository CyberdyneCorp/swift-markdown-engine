import SwiftUI

/// Computes node positions for a flowchart using simple longest-path layering.
struct FlowchartLayout {
    let frames: [String: CGRect]
    let size: CGSize

    private static let nodeHeight: CGFloat = 38
    private static let layerGap: CGFloat = 52
    private static let siblingGap: CGFloat = 28

    init(_ chart: Flowchart) {
        let layers = FlowchartLayout.assignLayers(chart)
        var byLayer: [Int: [String]] = [:]
        for node in chart.nodes {
            let layer = layers[node.id] ?? 0
            byLayer[layer, default: []].append(node.id)
        }
        let widths = Dictionary(uniqueKeysWithValues: chart.nodes.map { ($0.id, FlowchartLayout.width(for: $0)) })

        var frames: [String: CGRect] = [:]
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
        let horizontal = chart.direction == .leftToRight

        for layer in byLayer.keys.sorted() {
            let ids = byLayer[layer]!
            var cross: CGFloat = 0
            for id in ids {
                let w = widths[id] ?? 80
                let main = CGFloat(layer) * ((horizontal ? w : FlowchartLayout.nodeHeight) + FlowchartLayout.layerGap)
                let rect: CGRect
                if horizontal {
                    rect = CGRect(x: main, y: cross, width: w, height: FlowchartLayout.nodeHeight)
                    cross += FlowchartLayout.nodeHeight + FlowchartLayout.siblingGap
                } else {
                    rect = CGRect(x: cross, y: main, width: w, height: FlowchartLayout.nodeHeight)
                    cross += w + FlowchartLayout.siblingGap
                }
                frames[id] = rect
                maxX = max(maxX, rect.maxX)
                maxY = max(maxY, rect.maxY)
            }
        }
        self.frames = frames
        self.size = CGSize(width: maxX + 8, height: maxY + 8)
    }

    static func width(for node: FlowNode) -> CGFloat {
        max(64, CGFloat(node.label.count) * 8.5 + 28)
    }

    private static func assignLayers(_ chart: Flowchart) -> [String: Int] {
        var indegree: [String: Int] = [:]
        var adjacency: [String: [String]] = [:]
        for node in chart.nodes { indegree[node.id] = 0; adjacency[node.id] = [] }
        for edge in chart.edges where indegree[edge.to] != nil && indegree[edge.from] != nil {
            indegree[edge.to, default: 0] += 1
            adjacency[edge.from, default: []].append(edge.to)
        }
        var layer: [String: Int] = [:]
        var queue = chart.nodes.map(\.id).filter { indegree[$0] == 0 }
        if queue.isEmpty { queue = chart.nodes.first.map { [$0.id] } ?? [] }
        for id in queue { layer[id] = 0 }
        var visited = Set(queue)
        var frontier = queue
        var guardCount = 0
        while !frontier.isEmpty, guardCount < chart.nodes.count * 4 {
            guardCount += 1
            var next: [String] = []
            for id in frontier {
                for target in adjacency[id] ?? [] {
                    layer[target] = max(layer[target] ?? 0, (layer[id] ?? 0) + 1)
                    if !visited.contains(target) { visited.insert(target); next.append(target) }
                }
            }
            frontier = next
        }
        for node in chart.nodes where layer[node.id] == nil { layer[node.id] = 0 }
        return layer
    }
}

/// Renders a flowchart natively with SwiftUI Canvas.
struct FlowchartView: View {
    let chart: Flowchart
    let theme: MarkdownTheme

    private var layout: FlowchartLayout { FlowchartLayout(chart) }

    var body: some View {
        let layout = self.layout
        Canvas { context, _ in
            drawEdges(context, layout: layout)
            drawNodes(context, layout: layout)
        }
        .frame(width: layout.size.width, height: layout.size.height)
    }

    private func drawNodes(_ context: GraphicsContext, layout: FlowchartLayout) {
        for node in chart.nodes {
            guard let rect = layout.frames[node.id] else { continue }
            let path = shapePath(node.shape, in: rect)
            let fill = node.fill.flatMap(MermaidColor.parse) ?? theme.surface
            let stroke = node.stroke.flatMap(MermaidColor.parse) ?? theme.accent
            context.fill(path, with: .color(fill))
            context.stroke(path, with: .color(stroke), lineWidth: 1.5)
            let text = Text(node.label).font(.caption).foregroundColor(theme.textPrimary)
            context.draw(text, at: CGPoint(x: rect.midX, y: rect.midY))
        }
    }

    private func drawEdges(_ context: GraphicsContext, layout: FlowchartLayout) {
        for edge in chart.edges {
            guard let from = layout.frames[edge.from], let to = layout.frames[edge.to] else { continue }
            let start = CGPoint(x: from.midX, y: from.midY)
            let end = CGPoint(x: to.midX, y: to.midY)
            let p1 = borderPoint(from, toward: end)
            let p2 = borderPoint(to, toward: start)
            var path = Path()
            path.move(to: p1)
            path.addLine(to: p2)
            let style = StrokeStyle(lineWidth: edge.style == .thick ? 2.5 : 1.3,
                                    dash: edge.style == .dashed ? [4, 3] : [])
            context.stroke(path, with: .color(theme.textSecondary), style: style)
            if edge.hasArrow { drawArrowhead(context, at: p2, from: p1) }
            if let label = edge.label, !label.isEmpty {
                let mid = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
                let text = Text(label).font(.caption2).foregroundColor(theme.textSecondary)
                context.fill(Path(roundedRect: CGRect(x: mid.x - 22, y: mid.y - 9, width: 44, height: 18), cornerRadius: 4),
                             with: .color(theme.background))
                context.draw(text, at: mid)
            }
        }
    }

    private func drawArrowhead(_ context: GraphicsContext, at tip: CGPoint, from: CGPoint) {
        let angle = atan2(tip.y - from.y, tip.x - from.x)
        let size: CGFloat = 8
        let left = CGPoint(x: tip.x - size * cos(angle - .pi / 7), y: tip.y - size * sin(angle - .pi / 7))
        let right = CGPoint(x: tip.x - size * cos(angle + .pi / 7), y: tip.y - size * sin(angle + .pi / 7))
        var path = Path()
        path.move(to: tip); path.addLine(to: left); path.addLine(to: right); path.closeSubpath()
        context.fill(path, with: .color(theme.textSecondary))
    }

    private func borderPoint(_ rect: CGRect, toward target: CGPoint) -> CGPoint {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let dx = target.x - center.x
        let dy = target.y - center.y
        guard dx != 0 || dy != 0 else { return center }
        let scaleX = dx == 0 ? .infinity : (rect.width / 2) / abs(dx)
        let scaleY = dy == 0 ? .infinity : (rect.height / 2) / abs(dy)
        let scale = min(scaleX, scaleY)
        return CGPoint(x: center.x + dx * scale, y: center.y + dy * scale)
    }

    private func shapePath(_ shape: FlowShape, in rect: CGRect) -> Path {
        switch shape {
        case .rectangle, .subroutine:
            return Path(rect)
        case .rounded:
            return Path(roundedRect: rect, cornerRadius: 8)
        case .stadium:
            return Path(roundedRect: rect, cornerRadius: rect.height / 2)
        case .circle:
            return Path(ellipseIn: rect)
        case .diamond:
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
            return path
        case .hexagon:
            let inset = rect.width * 0.12
            var path = Path()
            path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
            return path
        }
    }
}
