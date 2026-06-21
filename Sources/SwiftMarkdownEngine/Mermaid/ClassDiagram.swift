import SwiftUI

struct ClassBox: Equatable {
    let name: String
    var members: [String]
}

struct ClassRelation: Equatable {
    let from: String
    let to: String
    var label: String?
    var inheritance: Bool
}

struct ClassModel: Equatable {
    var classes: [ClassBox]
    var relations: [ClassRelation]
}

enum ClassDiagramParser {
    static func parse(_ source: String) -> ClassModel {
        var classes: [String: [String]] = [:]
        var order: [String] = []
        var relations: [ClassRelation] = []

        func ensure(_ name: String) {
            let n = name.trimmingCharacters(in: .whitespaces)
            if classes[n] == nil { classes[n] = []; order.append(n) }
        }

        for line in MermaidLines.body(source) {
            if line.hasPrefix("class ") {
                let rest = String(line.dropFirst("class ".count))
                if let brace = rest.firstIndex(of: "{") {
                    let name = String(rest[..<brace]).trimmingCharacters(in: .whitespaces)
                    ensure(name)
                    let inner = rest[rest.index(after: brace)...].replacingOccurrences(of: "}", with: "")
                    for member in inner.split(separator: ";") where !member.trimmingCharacters(in: .whitespaces).isEmpty {
                        classes[name]?.append(member.trimmingCharacters(in: .whitespaces))
                    }
                } else {
                    ensure(rest.split(separator: " ").first.map(String.init) ?? rest)
                }
                continue
            }
            // Member line: `Animal : +int age`
            if let colon = line.firstIndex(of: ":"), !line.contains("--"), !line.contains("..") {
                let name = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
                let member = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                ensure(name)
                if !member.isEmpty { classes[name]?.append(member) }
                continue
            }
            if let relation = parseRelation(line) {
                ensure(relation.from); ensure(relation.to)
                relations.append(relation)
            }
        }
        return ClassModel(classes: order.map { ClassBox(name: $0, members: classes[$0] ?? []) }, relations: relations)
    }

    private static func parseRelation(_ line: String) -> ClassRelation? {
        var text = line
        var label: String?
        if let colon = text.firstIndex(of: ":") {
            label = String(text[text.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            text = String(text[..<colon])
        }
        let connectors = ["<|--", "--|>", "*--", "o--", "-->", "..>", "..|>", "--", ".."]
        for connector in connectors {
            if let range = text.range(of: connector) {
                let from = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let to = String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                guard !from.isEmpty, !to.isEmpty else { return nil }
                return ClassRelation(from: from, to: to, label: label, inheritance: connector.contains("|"))
            }
        }
        return nil
    }
}

/// Renders a class diagram: boxes with a name header and member list, connected by
/// relationship lines (hollow triangle for inheritance).
struct ClassDiagramView: View {
    let model: ClassModel
    let theme: MarkdownTheme

    private func boxSize(_ box: ClassBox) -> CGSize {
        let widest = ([box.name] + box.members).map(\.count).max() ?? box.name.count
        let width = max(90, CGFloat(widest) * 7.5 + 20)
        let height = 26 + CGFloat(box.members.count) * 16 + (box.members.isEmpty ? 0 : 6)
        return CGSize(width: width, height: height)
    }

    var body: some View {
        let ids = model.classes.map(\.name)
        let sizes = Dictionary(uniqueKeysWithValues: model.classes.map { ($0.name, boxSize($0)) })
        let layers = GraphLayout.assignLayers(nodeIDs: ids, edges: model.relations.map { ($0.from, $0.to) })
        let layout = GraphLayout.positions(nodeIDs: ids, sizes: sizes, layers: layers)

        Canvas { context, _ in
            for relation in model.relations {
                guard let f = layout.frames[relation.from], let t = layout.frames[relation.to] else { continue }
                var path = Path()
                path.move(to: CGPoint(x: f.midX, y: f.midY))
                path.addLine(to: CGPoint(x: t.midX, y: t.midY))
                context.stroke(path, with: .color(theme.textSecondary), lineWidth: 1.2)
            }
            for box in model.classes {
                guard let rect = layout.frames[box.name] else { continue }
                context.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(theme.surface))
                context.stroke(Path(roundedRect: rect, cornerRadius: 4), with: .color(theme.accent), lineWidth: 1)
                context.draw(Text(box.name).font(.caption.bold()).foregroundColor(theme.textPrimary),
                             at: CGPoint(x: rect.midX, y: rect.minY + 13))
                var memberPath = Path()
                memberPath.move(to: CGPoint(x: rect.minX, y: rect.minY + 26))
                memberPath.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 26))
                context.stroke(memberPath, with: .color(theme.border), lineWidth: 0.5)
                for (index, member) in box.members.enumerated() {
                    context.draw(Text(member).font(.caption2).foregroundColor(theme.textSecondary),
                                 at: CGPoint(x: rect.minX + 8, y: rect.minY + 36 + CGFloat(index) * 16), anchor: .leading)
                }
            }
        }
        .diagramFrame(width: layout.size.width, height: layout.size.height)
    }
}
