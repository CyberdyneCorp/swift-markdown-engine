import SwiftUI

struct SequenceMessage: Equatable {
    let from: String
    let to: String
    let text: String
    let dashed: Bool
}

struct SequenceModel: Equatable {
    let participants: [String]
    let messages: [SequenceMessage]
}

enum SequenceParser {
    static func parse(_ source: String) -> SequenceModel {
        var participants: [String] = []
        var messages: [SequenceMessage] = []

        func add(_ name: String) {
            let n = name.trimmingCharacters(in: .whitespaces)
            if !n.isEmpty, !participants.contains(n) { participants.append(n) }
        }

        for line in MermaidLines.body(source) {
            if line.hasPrefix("participant ") || line.hasPrefix("actor ") {
                let name = line.split(separator: " ", maxSplits: 1).dropFirst().first.map(String.init) ?? ""
                add(name.split(separator: " ").first.map(String.init) ?? name)
                continue
            }
            if line.hasPrefix("Note ") || line.hasPrefix("note ") || line.hasPrefix("loop ")
                || line.hasPrefix("alt ") || line.hasPrefix("opt ") || line == "end" { continue }
            if let message = parseMessage(line) {
                add(message.from); add(message.to)
                messages.append(message)
            }
        }
        return SequenceModel(participants: participants, messages: messages)
    }

    private static func parseMessage(_ line: String) -> SequenceMessage? {
        guard let colon = line.firstIndex(of: ":") else { return nil }
        let left = String(line[..<colon])
        let text = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
        // Connectors, longest first.
        let connectors = ["-->>", "->>", "-->", "-)", "->", "--x", "-x"]
        for connector in connectors {
            if let range = left.range(of: connector) {
                let from = String(left[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let to = String(left[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                guard !from.isEmpty, !to.isEmpty else { return nil }
                return SequenceMessage(from: from, to: to, text: text, dashed: connector.hasPrefix("--"))
            }
        }
        return nil
    }
}

/// Renders a sequence diagram: participant headers, lifelines, and ordered messages.
struct SequenceDiagramView: View {
    let model: SequenceModel
    let theme: MarkdownTheme

    private let columnWidth: CGFloat = 120
    private let headerHeight: CGFloat = 36
    private let messageGap: CGFloat = 40
    private let topPadding: CGFloat = 8

    private var size: CGSize {
        CGSize(width: max(1, CGFloat(model.participants.count)) * columnWidth,
               height: topPadding + headerHeight + CGFloat(model.messages.count + 1) * messageGap)
    }

    var body: some View {
        Canvas { context, _ in
            let columns = columnCenters()
            drawLifelines(context, columns: columns)
            drawMessages(context, columns: columns)
            drawHeaders(context, columns: columns)
        }
        .frame(width: size.width, height: size.height)
    }

    private func columnCenters() -> [String: CGFloat] {
        var centers: [String: CGFloat] = [:]
        for (index, name) in model.participants.enumerated() {
            centers[name] = CGFloat(index) * columnWidth + columnWidth / 2
        }
        return centers
    }

    private func drawLifelines(_ context: GraphicsContext, columns: [String: CGFloat]) {
        for name in model.participants {
            guard let x = columns[name] else { continue }
            var path = Path()
            path.move(to: CGPoint(x: x, y: topPadding + headerHeight))
            path.addLine(to: CGPoint(x: x, y: size.height - 4))
            context.stroke(path, with: .color(theme.border), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
    }

    private func drawHeaders(_ context: GraphicsContext, columns: [String: CGFloat]) {
        for name in model.participants {
            guard let x = columns[name] else { continue }
            let rect = CGRect(x: x - columnWidth / 2 + 8, y: topPadding, width: columnWidth - 16, height: headerHeight - 6)
            context.fill(Path(roundedRect: rect, cornerRadius: 6), with: .color(theme.surface))
            context.stroke(Path(roundedRect: rect, cornerRadius: 6), with: .color(theme.accent), lineWidth: 1)
            context.draw(Text(name).font(.caption).foregroundColor(theme.textPrimary),
                         at: CGPoint(x: x, y: topPadding + (headerHeight - 6) / 2))
        }
    }

    private func drawMessages(_ context: GraphicsContext, columns: [String: CGFloat]) {
        for (index, message) in model.messages.enumerated() {
            guard let fromX = columns[message.from], let toX = columns[message.to] else { continue }
            let y = topPadding + headerHeight + CGFloat(index + 1) * messageGap
            var path = Path()
            path.move(to: CGPoint(x: fromX, y: y))
            path.addLine(to: CGPoint(x: toX, y: y))
            context.stroke(path, with: .color(theme.textSecondary),
                           style: StrokeStyle(lineWidth: 1.3, dash: message.dashed ? [4, 3] : []))
            drawArrowhead(context, at: CGPoint(x: toX, y: y), pointingRight: toX >= fromX)
            let mid = CGPoint(x: (fromX + toX) / 2, y: y - 9)
            context.draw(Text(message.text).font(.caption2).foregroundColor(theme.textPrimary), at: mid)
        }
    }

    private func drawArrowhead(_ context: GraphicsContext, at tip: CGPoint, pointingRight: Bool) {
        let dx: CGFloat = pointingRight ? -8 : 8
        var path = Path()
        path.move(to: tip)
        path.addLine(to: CGPoint(x: tip.x + dx, y: tip.y - 4))
        path.addLine(to: CGPoint(x: tip.x + dx, y: tip.y + 4))
        path.closeSubpath()
        context.fill(path, with: .color(theme.textSecondary))
    }
}
