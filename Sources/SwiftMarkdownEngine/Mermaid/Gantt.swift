import SwiftUI

struct GanttTask: Equatable {
    let section: String
    let label: String
    let start: Double      // in days from project start
    let duration: Double   // in days
    let isMilestone: Bool
}

struct GanttModel: Equatable {
    let title: String?
    let tasks: [GanttTask]
}

enum GanttParser {
    private static let statuses: Set<String> = ["done", "active", "crit", "milestone"]

    static func parse(_ source: String) -> GanttModel {
        var title: String?
        var section = ""
        var tasks: [GanttTask] = []
        var endByID: [String: Double] = [:]
        var lastEnd: Double = 0

        for line in MermaidLines.body(source) {
            if line.hasPrefix("title ") { title = String(line.dropFirst("title ".count)); continue }
            if line.hasPrefix("dateFormat") || line.hasPrefix("axisFormat") || line.hasPrefix("excludes") { continue }
            if line.hasPrefix("section ") { section = String(line.dropFirst("section ".count)); continue }
            guard let colon = line.firstIndex(of: ":") else { continue }

            let label = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
            let tokens = line[line.index(after: colon)...]
                .split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            var isMilestone = false
            var identifier: String?
            var afterID: String?
            var duration: Double = 1

            for token in tokens {
                if statuses.contains(token) { if token == "milestone" { isMilestone = true }; continue }
                if token.hasPrefix("after ") { afterID = String(token.dropFirst("after ".count)); continue }
                if let days = parseDuration(token) { duration = days; continue }
                if isIdentifier(token), identifier == nil { identifier = token }
            }

            let start = afterID.flatMap { endByID[$0] } ?? lastEnd
            let end = start + duration
            lastEnd = end
            if let identifier { endByID[identifier] = end }
            tasks.append(GanttTask(section: section, label: label, start: start, duration: duration, isMilestone: isMilestone))
        }
        return GanttModel(title: title, tasks: tasks)
    }

    private static func parseDuration(_ token: String) -> Double? {
        guard let unit = token.last, "dwh".contains(unit), let value = Double(token.dropLast()) else { return nil }
        switch unit { case "w": return value * 7; case "h": return value / 24; default: return value }
    }

    private static func isIdentifier(_ token: String) -> Bool {
        !token.isEmpty && token.first!.isLetter && !token.contains(" ") && !token.contains("-")
    }
}

/// Renders a Gantt chart: one bar per task, grouped by section.
struct GanttView: View {
    let model: GanttModel
    let theme: MarkdownTheme

    private let rowHeight: CGFloat = 26
    private let labelWidth: CGFloat = 130
    private let dayScale: CGFloat = 14

    private var maxEnd: Double { model.tasks.map { $0.start + $0.duration }.max() ?? 1 }

    var body: some View {
        let width = labelWidth + CGFloat(maxEnd) * dayScale + 16
        let height = CGFloat(model.tasks.count) * rowHeight + 28
        Canvas { context, _ in
            if let title = model.title {
                context.draw(Text(title).font(.caption.bold()).foregroundColor(theme.textPrimary),
                             at: CGPoint(x: width / 2, y: 10))
            }
            var lastSection = ""
            for (index, task) in model.tasks.enumerated() {
                let y = 24 + CGFloat(index) * rowHeight
                let showSection = task.section != lastSection
                lastSection = task.section
                let labelText = showSection ? "\(task.section) · \(task.label)" : task.label
                context.draw(Text(labelText).font(.caption2).foregroundColor(theme.textSecondary),
                             at: CGPoint(x: 4, y: y + rowHeight / 2), anchor: .leading)
                let barX = labelWidth + CGFloat(task.start) * dayScale
                let barWidth = max(task.isMilestone ? rowHeight - 12 : 6, CGFloat(task.duration) * dayScale)
                let rect = CGRect(x: barX, y: y + 4, width: barWidth, height: rowHeight - 12)
                let shape = task.isMilestone ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 4)
                context.fill(shape, with: .color(theme.accent))
            }
        }
        .frame(width: width, height: height)
    }
}
