import SwiftUI

// MARK: - Model

enum FlowShape: Equatable {
    case rectangle, rounded, stadium, circle, diamond, hexagon, subroutine
}

struct FlowNode: Equatable {
    let id: String
    var label: String
    var shape: FlowShape
    var fill: String?
    var stroke: String?
}

struct FlowEdge: Equatable {
    enum Style { case solid, dashed, thick }
    let from: String
    let to: String
    var label: String?
    var style: Style
    var hasArrow: Bool
}

struct Flowchart: Equatable {
    enum Direction { case topToBottom, leftToRight }
    var direction: Direction
    var nodes: [FlowNode]
    var edges: [FlowEdge]
}

// MARK: - Parser

enum FlowchartParser {
    static func parse(_ source: String) -> Flowchart {
        let direction = parseDirection(source)
        var nodes: [String: FlowNode] = [:]
        var order: [String] = []
        var edges: [FlowEdge] = []
        var styles: [String: (fill: String?, stroke: String?)] = [:]

        func register(_ token: String) -> String? {
            guard let node = parseNode(token) else { return nil }
            if nodes[node.id] == nil { order.append(node.id) }
            // Preserve a previously parsed richer label/shape when this token is bare.
            if let existing = nodes[node.id], node.shape == .rectangle, node.label == node.id {
                nodes[node.id] = existing
            } else {
                nodes[node.id] = node
            }
            return node.id
        }

        for raw in MermaidLines.body(source) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("subgraph") || line == "end" || line.hasPrefix("direction") { continue }
            if line.hasPrefix("style ") {
                if let (id, style) = parseStyle(line) { styles[id] = style }
                continue
            }
            let (tokens, connectors) = tokenize(line)
            guard !connectors.isEmpty else { _ = register(line); continue }
            let ids = tokens.compactMap { register($0) }
            guard ids.count == tokens.count else { continue }
            for (index, connector) in connectors.enumerated() where index + 1 < ids.count {
                edges.append(FlowEdge(from: ids[index], to: ids[index + 1],
                                      label: connector.label, style: connector.style, hasArrow: connector.hasArrow))
            }
        }
        // Apply style directives.
        for (id, style) in styles where nodes[id] != nil {
            nodes[id]?.fill = style.fill
            nodes[id]?.stroke = style.stroke
        }
        return Flowchart(direction: direction, nodes: order.compactMap { nodes[$0] }, edges: edges)
    }

    private static func parseDirection(_ source: String) -> Flowchart.Direction {
        let header = source.split(separator: "\n").first.map { $0.lowercased() } ?? ""
        if header.contains("lr") || header.contains("rl") { return .leftToRight }
        return .topToBottom
    }

    private static func parseNode(_ token: String) -> FlowNode? {
        let t = token.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return nil }
        // Match id followed by an optional bracketed label.
        let shapes: [(open: String, close: String, shape: FlowShape)] = [
            ("([", "])", .stadium), ("[[", "]]", .subroutine), ("((", "))", .circle),
            ("{{", "}}", .hexagon), ("[", "]", .rectangle), ("(", ")", .rounded), ("{", "}", .diamond),
        ]
        for spec in shapes {
            if let openRange = t.range(of: spec.open), t.hasSuffix(spec.close) {
                let id = String(t[..<openRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let labelStart = openRange.upperBound
                let labelEnd = t.index(t.endIndex, offsetBy: -spec.close.count)
                guard labelStart <= labelEnd, !id.isEmpty else { continue }
                var label = String(t[labelStart..<labelEnd]).trimmingCharacters(in: .whitespaces)
                label = label.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                return FlowNode(id: id, label: label.isEmpty ? id : label, shape: spec.shape, fill: nil, stroke: nil)
            }
        }
        // Bare identifier.
        let id = t.split(whereSeparator: { $0 == " " }).first.map(String.init) ?? t
        return FlowNode(id: id, label: id, shape: .rectangle, fill: nil, stroke: nil)
    }

    private struct Connector { var style: FlowEdge.Style; var hasArrow: Bool; var label: String? }

    private static func tokenize(_ line: String) -> (tokens: [String], connectors: [Connector]) {
        let chars = Array(line)
        var tokens: [String] = []
        var connectors: [Connector] = []
        var current = ""
        var depth = 0
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if "([{".contains(c) { depth += 1; current.append(c); i += 1; continue }
            if ")]}".contains(c) { depth = max(0, depth - 1); current.append(c); i += 1; continue }
            if depth == 0, c == "-" || c == "=" {
                let runStart = i
                while i < chars.count, "-=.>o<".contains(chars[i]) { i += 1 }
                let conn = String(chars[runStart..<i])
                guard conn.contains("-") || conn.contains("=") else { current.append(c); continue }
                var label: String?
                if i < chars.count, chars[i] == "|" {
                    let lblStart = i + 1; i += 1
                    while i < chars.count, chars[i] != "|" { i += 1 }
                    label = String(chars[lblStart..<min(i, chars.count)])
                    if i < chars.count { i += 1 }
                }
                tokens.append(current.trimmingCharacters(in: .whitespaces)); current = ""
                let style: FlowEdge.Style = conn.contains(".") ? .dashed : (conn.contains("=") ? .thick : .solid)
                connectors.append(Connector(style: style, hasArrow: conn.contains(">"), label: label))
            } else {
                current.append(c); i += 1
            }
        }
        tokens.append(current.trimmingCharacters(in: .whitespaces))
        return (tokens, connectors)
    }

    private static func parseStyle(_ line: String) -> (String, (fill: String?, stroke: String?))? {
        let parts = line.dropFirst("style ".count).split(separator: " ", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        let id = String(parts[0])
        var fill: String?
        var stroke: String?
        for attr in parts[1].split(separator: ",") {
            let kv = attr.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard kv.count == 2 else { continue }
            if kv[0] == "fill" { fill = kv[1] }
            if kv[0] == "stroke" { stroke = kv[1] }
        }
        return (id, (fill, stroke))
    }
}
