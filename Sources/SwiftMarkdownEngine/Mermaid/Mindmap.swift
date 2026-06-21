import SwiftUI

struct MindNode: Equatable {
    let label: String
    let depth: Int
    var children: [Int]   // indices into the flat node array
}

struct MindmapModel: Equatable {
    var nodes: [MindNode]   // node 0 is the root, if present
}

enum MindmapParser {
    static func parse(_ source: String) -> MindmapModel {
        // Mindmaps are indentation-sensitive, so keep raw leading whitespace.
        let rawLines = source.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var nodes: [MindNode] = []
        var stack: [(indent: Int, index: Int)] = []
        var started = false

        for raw in rawLines {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("%%") { continue }
            if !started { started = true; if trimmed.lowercased() == "mindmap" { continue } }
            let indent = raw.prefix { $0 == " " || $0 == "\t" }.reduce(0) { $0 + ($1 == "\t" ? 2 : 1) }
            let label = cleanLabel(trimmed)

            // Pop the stack to the parent whose indent is smaller.
            while let top = stack.last, top.indent >= indent { stack.removeLast() }
            let newIndex = nodes.count
            nodes.append(MindNode(label: label, depth: stack.count, children: []))
            if let parent = stack.last { nodes[parent.index].children.append(newIndex) }
            stack.append((indent, newIndex))
        }
        return MindmapModel(nodes: nodes)
    }

    private static func cleanLabel(_ text: String) -> String {
        var t = text
        for (open, close) in [("((", "))"), ("[", "]"), ("(", ")"), ("{{", "}}")] {
            if let range = t.range(of: open), t.hasSuffix(close) {
                t = String(t[range.upperBound..<t.index(t.endIndex, offsetBy: -close.count)])
                break
            }
        }
        return t.trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
    }
}

/// Renders a mindmap as a left-to-right tree.
struct MindmapView: View {
    let model: MindmapModel
    let theme: MarkdownTheme

    private let columnWidth: CGFloat = 130
    private let rowHeight: CGFloat = 34

    var body: some View {
        let frames = computeFrames()
        Canvas { context, _ in
            // Edges parent -> child.
            for (index, node) in model.nodes.enumerated() {
                guard let parentRect = frames[index] else { continue }
                for child in node.children {
                    guard let childRect = frames[child] else { continue }
                    var path = Path()
                    path.move(to: CGPoint(x: parentRect.maxX, y: parentRect.midY))
                    path.addLine(to: CGPoint(x: childRect.minX, y: childRect.midY))
                    context.stroke(path, with: .color(theme.textSecondary), lineWidth: 1)
                }
            }
            for (index, node) in model.nodes.enumerated() {
                guard let rect = frames[index] else { continue }
                context.fill(Path(roundedRect: rect, cornerRadius: rect.height / 2), with: .color(theme.surface))
                context.stroke(Path(roundedRect: rect, cornerRadius: rect.height / 2),
                               with: .color(theme.accent), lineWidth: index == 0 ? 2 : 1)
                context.draw(Text(node.label).font(.caption).foregroundColor(theme.textPrimary),
                             at: CGPoint(x: rect.midX, y: rect.midY))
            }
        }
        .diagramFrame(width: canvasSize(frames).width, height: canvasSize(frames).height)
    }

    private func computeFrames() -> [Int: CGRect] {
        var frames: [Int: CGRect] = [:]
        var nextLeafY: CGFloat = 0

        func place(_ index: Int) -> CGFloat {
            let node = model.nodes[index]
            let x = CGFloat(node.depth) * columnWidth + 4
            let width = max(70, CGFloat(node.label.count) * 7 + 20)
            let y: CGFloat
            if node.children.isEmpty {
                y = nextLeafY * rowHeight + 4
                nextLeafY += 1
            } else {
                let childYs = node.children.map { place($0) }
                y = (childYs.min()! + childYs.max()!) / 2
            }
            frames[index] = CGRect(x: x, y: y, width: width, height: rowHeight - 8)
            return y
        }

        if !model.nodes.isEmpty { _ = place(0) }
        return frames
    }

    private func canvasSize(_ frames: [Int: CGRect]) -> CGSize {
        let maxX = frames.values.map(\.maxX).max() ?? 1
        let maxY = frames.values.map(\.maxY).max() ?? 1
        return CGSize(width: maxX + 8, height: maxY + 8)
    }
}
