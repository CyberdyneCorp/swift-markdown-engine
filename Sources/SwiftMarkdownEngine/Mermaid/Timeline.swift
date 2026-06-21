import SwiftUI

struct TimelineEntry: Equatable {
    let section: String?
    let period: String
    let events: [String]
}

struct TimelineModel: Equatable {
    let title: String?
    let entries: [TimelineEntry]
}

enum TimelineParser {
    static func parse(_ source: String) -> TimelineModel {
        var title: String?
        var section: String?
        var entries: [TimelineEntry] = []

        for line in MermaidLines.body(source) {
            if line.hasPrefix("title ") { title = String(line.dropFirst("title ".count)); continue }
            if line.hasPrefix("section ") { section = String(line.dropFirst("section ".count)); continue }
            let parts = line.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            guard let period = parts.first, !period.isEmpty else { continue }
            let events = Array(parts.dropFirst()).filter { !$0.isEmpty }
            entries.append(TimelineEntry(section: section, period: period, events: events))
        }
        return TimelineModel(title: title, entries: entries)
    }
}

/// Renders a timeline: periods along a horizontal axis with their events stacked
/// beneath each period marker.
struct TimelineView: View {
    let model: TimelineModel
    let theme: MarkdownTheme

    private let columnGap: CGFloat = 130
    private let eventHeight: CGFloat = 18

    var body: some View {
        let width = max(columnGap, CGFloat(model.entries.count) * columnGap) + 20
        let maxEvents = model.entries.map(\.events.count).max() ?? 0
        let height = 80 + CGFloat(maxEvents) * eventHeight

        Canvas { context, _ in
            if let title = model.title {
                context.draw(Text(title).font(.caption.bold()).foregroundColor(theme.textPrimary),
                             at: CGPoint(x: width / 2, y: 10))
            }
            let axisY: CGFloat = 36
            var axis = Path()
            axis.move(to: CGPoint(x: 20, y: axisY))
            axis.addLine(to: CGPoint(x: width - 10, y: axisY))
            context.stroke(axis, with: .color(theme.border), lineWidth: 2)

            for (index, entry) in model.entries.enumerated() {
                let x = 40 + CGFloat(index) * columnGap
                let dot = CGRect(x: x - 5, y: axisY - 5, width: 10, height: 10)
                context.fill(Path(ellipseIn: dot), with: .color(theme.accent))
                context.draw(Text(entry.period).font(.caption.bold()).foregroundColor(theme.textPrimary),
                             at: CGPoint(x: x, y: axisY - 16))
                for (eventIndex, event) in entry.events.enumerated() {
                    let y = axisY + 16 + CGFloat(eventIndex) * eventHeight
                    let rect = CGRect(x: x - 50, y: y - 7, width: 100, height: 15)
                    context.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(theme.surface))
                    context.draw(Text(event).font(.system(size: 9)).foregroundColor(theme.textPrimary),
                                 at: CGPoint(x: x, y: y))
                }
            }
        }
        .diagramFrame(width: width, height: height)
    }
}
