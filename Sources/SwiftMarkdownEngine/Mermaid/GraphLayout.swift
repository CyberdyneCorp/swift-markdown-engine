import CoreGraphics

/// Shared longest-path layer assignment for graph-style diagrams (class, ER).
enum GraphLayout {
    /// Assigns each node id a layer index via longest path from roots.
    static func assignLayers(nodeIDs: [String], edges: [(from: String, to: String)]) -> [String: Int] {
        var indegree = Dictionary(uniqueKeysWithValues: nodeIDs.map { ($0, 0) })
        var adjacency = Dictionary(uniqueKeysWithValues: nodeIDs.map { ($0, [String]()) })
        for edge in edges where indegree[edge.to] != nil && indegree[edge.from] != nil {
            indegree[edge.to]! += 1
            adjacency[edge.from]!.append(edge.to)
        }
        var layer: [String: Int] = [:]
        var frontier = nodeIDs.filter { indegree[$0] == 0 }
        if frontier.isEmpty { frontier = nodeIDs.first.map { [$0] } ?? [] }
        for id in frontier { layer[id] = 0 }
        var visited = Set(frontier)
        var guardCount = 0
        while !frontier.isEmpty, guardCount < nodeIDs.count * 4 {
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
        for id in nodeIDs where layer[id] == nil { layer[id] = 0 }
        return layer
    }

    /// Positions boxes of varying size by layer (top-to-bottom), centering each
    /// layer's boxes horizontally. Returns frames and the total canvas size.
    static func positions(
        nodeIDs: [String],
        sizes: [String: CGSize],
        layers: [String: Int],
        layerGap: CGFloat = 56,
        siblingGap: CGFloat = 28
    ) -> (frames: [String: CGRect], size: CGSize) {
        var byLayer: [Int: [String]] = [:]
        for id in nodeIDs { byLayer[layers[id] ?? 0, default: []].append(id) }

        var rowHeights: [Int: CGFloat] = [:]
        var rowWidths: [Int: CGFloat] = [:]
        for (layer, ids) in byLayer {
            rowHeights[layer] = ids.map { sizes[$0]?.height ?? 40 }.max() ?? 40
            rowWidths[layer] = ids.reduce(0) { $0 + (sizes[$1]?.width ?? 80) } + CGFloat(max(0, ids.count - 1)) * siblingGap
        }
        let maxWidth = rowWidths.values.max() ?? 0

        var frames: [String: CGRect] = [:]
        var y: CGFloat = 4
        for layer in byLayer.keys.sorted() {
            let ids = byLayer[layer]!
            var x = (maxWidth - (rowWidths[layer] ?? 0)) / 2 + 4
            let rowHeight = rowHeights[layer] ?? 40
            for id in ids {
                let s = sizes[id] ?? CGSize(width: 80, height: 40)
                frames[id] = CGRect(x: x, y: y, width: s.width, height: s.height)
                x += s.width + siblingGap
            }
            y += rowHeight + layerGap
        }
        return (frames, CGSize(width: maxWidth + 8, height: y + 4))
    }
}
