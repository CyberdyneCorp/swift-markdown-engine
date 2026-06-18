import Foundation

/// Parses a Mermaid state diagram into a `Flowchart` so it can reuse the flowchart
/// layout and Canvas renderer. `[*]` start/end markers become small circle nodes.
enum StateDiagramParser {
    static func parse(_ source: String) -> Flowchart {
        var nodes: [String: FlowNode] = [:]
        var order: [String] = []
        var edges: [FlowEdge] = []
        var startCounter = 0

        func node(for token: String) -> String {
            let t = token.trimmingCharacters(in: .whitespaces)
            if t == "[*]" {
                startCounter += 1
                let id = "__state_marker_\(startCounter)"
                nodes[id] = FlowNode(id: id, label: "", shape: .circle, fill: nil, stroke: nil)
                order.append(id)
                return id
            }
            if nodes[t] == nil {
                nodes[t] = FlowNode(id: t, label: t, shape: .rounded, fill: nil, stroke: nil)
                order.append(t)
            }
            return t
        }

        for line in MermaidLines.body(source) {
            if line.hasPrefix("state ") || line == "}" || line.hasPrefix("note ") { continue }
            guard let arrow = line.range(of: "-->") else {
                // Standalone state declaration like `Still`.
                if !line.isEmpty, !line.contains(":") { _ = node(for: line) }
                continue
            }
            let lhs = String(line[..<arrow.lowerBound])
            var rhs = String(line[arrow.upperBound...])
            var label: String?
            if let colon = rhs.firstIndex(of: ":") {
                label = String(rhs[rhs.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                rhs = String(rhs[..<colon])
            }
            let from = node(for: lhs)
            let to = node(for: rhs)
            edges.append(FlowEdge(from: from, to: to, label: label, style: .solid, hasArrow: true))
        }
        return Flowchart(direction: .topToBottom, nodes: order.compactMap { nodes[$0] }, edges: edges)
    }
}
