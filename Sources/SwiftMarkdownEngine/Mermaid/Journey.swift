import SwiftUI

struct JourneyTask: Equatable {
    let section: String
    let label: String
    let score: Int
    let actors: String
}

struct JourneyModel: Equatable {
    let title: String?
    let tasks: [JourneyTask]
}

enum JourneyParser {
    static func parse(_ source: String) -> JourneyModel {
        var title: String?
        var section = ""
        var tasks: [JourneyTask] = []

        for line in MermaidLines.body(source) {
            if line.hasPrefix("title ") { title = String(line.dropFirst("title ".count)); continue }
            if line.hasPrefix("section ") { section = String(line.dropFirst("section ".count)); continue }
            // Task: Label: score: actors
            let parts = line.split(separator: ":", maxSplits: 2).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count >= 2, let score = Int(parts[1]) else { continue }
            let actors = parts.count > 2 ? parts[2] : ""
            tasks.append(JourneyTask(section: section, label: parts[0], score: min(max(score, 1), 5), actors: actors))
        }
        return JourneyModel(title: title, tasks: tasks)
    }
}

/// Renders a user journey: tasks as score-colored nodes along a path, grouped by
/// section.
struct JourneyView: View {
    let model: JourneyModel
    let theme: MarkdownTheme

    private let nodeGap: CGFloat = 110
    private let radius: CGFloat = 16

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 1: return Color(.sRGB, red: 0.85, green: 0.30, blue: 0.30)
        case 2: return Color(.sRGB, red: 0.92, green: 0.55, blue: 0.25)
        case 3: return Color(.sRGB, red: 0.92, green: 0.80, blue: 0.25)
        case 4: return Color(.sRGB, red: 0.55, green: 0.78, blue: 0.35)
        default: return Color(.sRGB, red: 0.30, green: 0.72, blue: 0.45)
        }
    }

    var body: some View {
        let width = max(nodeGap, CGFloat(model.tasks.count) * nodeGap) + 20
        Canvas { context, _ in
            if let title = model.title {
                context.draw(Text(title).font(.caption.bold()).foregroundColor(theme.textPrimary),
                             at: CGPoint(x: width / 2, y: 10))
            }
            let centerY: CGFloat = 60
            // Connecting path.
            if model.tasks.count > 1 {
                var path = Path()
                path.move(to: CGPoint(x: 30, y: centerY))
                path.addLine(to: CGPoint(x: 30 + CGFloat(model.tasks.count - 1) * nodeGap, y: centerY))
                context.stroke(path, with: .color(theme.border), lineWidth: 2)
            }
            for (index, task) in model.tasks.enumerated() {
                let x = 30 + CGFloat(index) * nodeGap
                let rect = CGRect(x: x - radius, y: centerY - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: rect), with: .color(scoreColor(task.score)))
                context.draw(Text("\(task.score)").font(.caption.bold()).foregroundColor(.white),
                             at: CGPoint(x: x, y: centerY))
                context.draw(Text(task.label).font(.caption2).foregroundColor(theme.textPrimary),
                             at: CGPoint(x: x, y: centerY + radius + 12))
                if !task.actors.isEmpty {
                    context.draw(Text(task.actors).font(.system(size: 9)).foregroundColor(theme.textSecondary),
                                 at: CGPoint(x: x, y: centerY + radius + 26))
                }
            }
        }
        .frame(width: width, height: 110)
    }
}
