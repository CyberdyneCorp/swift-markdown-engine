import SwiftUI

struct ERRelation: Equatable {
    let left: String
    let right: String
    let leftCardinality: String
    let rightCardinality: String
    var label: String?
}

struct ERModel: Equatable {
    var entities: [String]
    var relations: [ERRelation]
}

enum ERDiagramParser {
    static func parse(_ source: String) -> ERModel {
        var entities: [String] = []
        var relations: [ERRelation] = []
        var insideBlock = false

        func ensure(_ name: String) {
            let n = name.trimmingCharacters(in: .whitespaces)
            if !n.isEmpty, !entities.contains(n) { entities.append(n) }
        }

        for line in MermaidLines.body(source) {
            if insideBlock { if line.contains("}") { insideBlock = false }; continue }
            // Relations are checked first: a cardinality like `o{` contains a brace
            // that must not be mistaken for an entity-attribute block.
            if line.contains("--"), let relation = parseRelation(line) {
                ensure(relation.left); ensure(relation.right)
                relations.append(relation)
                continue
            }
            if let brace = line.firstIndex(of: "{") {
                ensure(String(line[..<brace]))
                if !line.contains("}") { insideBlock = true }
                continue
            }
            if !line.isEmpty, !line.contains(":") {
                ensure(line)
            }
        }
        return ERModel(entities: entities, relations: relations)
    }

    private static func parseRelation(_ line: String) -> ERRelation? {
        guard let dashes = line.range(of: "--") else { return nil }
        let left = String(line[..<dashes.lowerBound]).trimmingCharacters(in: .whitespaces)
        var right = String(line[dashes.upperBound...]).trimmingCharacters(in: .whitespaces)
        var label: String?
        if let colon = right.firstIndex(of: ":") {
            label = String(right[right.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            right = String(right[..<colon]).trimmingCharacters(in: .whitespaces)
        }
        let leftParts = left.split(separator: " ")
        let rightParts = right.split(separator: " ")
        guard let leftName = leftParts.first, let rightName = rightParts.last else { return nil }
        let leftCard = leftParts.count > 1 ? String(leftParts.last!) : ""
        let rightCard = rightParts.count > 1 ? String(rightParts.first!) : ""
        return ERRelation(left: String(leftName), right: String(rightName),
                          leftCardinality: leftCard, rightCardinality: rightCard, label: label)
    }
}

/// Renders an ER diagram: entity boxes connected by relationship lines labeled with
/// their cardinality and verb.
struct ERDiagramView: View {
    let model: ERModel
    let theme: MarkdownTheme

    private func entitySize(_ name: String) -> CGSize {
        CGSize(width: max(80, CGFloat(name.count) * 8.5 + 24), height: 34)
    }

    var body: some View {
        let sizes = Dictionary(uniqueKeysWithValues: model.entities.map { ($0, entitySize($0)) })
        let layers = GraphLayout.assignLayers(nodeIDs: model.entities, edges: model.relations.map { ($0.left, $0.right) })
        let layout = GraphLayout.positions(nodeIDs: model.entities, sizes: sizes, layers: layers)

        Canvas { context, _ in
            for relation in model.relations {
                guard let l = layout.frames[relation.left], let r = layout.frames[relation.right] else { continue }
                let p1 = CGPoint(x: l.midX, y: l.midY)
                let p2 = CGPoint(x: r.midX, y: r.midY)
                var path = Path(); path.move(to: p1); path.addLine(to: p2)
                context.stroke(path, with: .color(theme.textSecondary), lineWidth: 1.2)
                if let label = relation.label {
                    let mid = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
                    context.draw(Text(label).font(.caption2).foregroundColor(theme.textSecondary), at: mid)
                }
            }
            for name in model.entities {
                guard let rect = layout.frames[name] else { continue }
                context.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(theme.surface))
                context.stroke(Path(roundedRect: rect, cornerRadius: 4), with: .color(theme.accent), lineWidth: 1)
                context.draw(Text(name).font(.caption.bold()).foregroundColor(theme.textPrimary),
                             at: CGPoint(x: rect.midX, y: rect.midY))
            }
        }
        .diagramFrame(width: layout.size.width, height: layout.size.height)
    }
}
