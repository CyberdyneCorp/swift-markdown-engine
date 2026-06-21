import SwiftUI

struct GitCommit: Equatable {
    let column: Int      // sequential position along the x axis
    let lane: Int        // branch lane (y)
    let branch: String
    var label: String?
    var isMerge: Bool
}

struct GitGraphModel: Equatable {
    let commits: [GitCommit]
    let laneCount: Int
}

enum GitGraphParser {
    static func parse(_ source: String) -> GitGraphModel {
        var lanes: [String: Int] = ["main": 0]
        var branchTip: [String: Int] = [:]   // last column index per branch
        var current = "main"
        var column = 0
        var commits: [GitCommit] = []

        func laneFor(_ branch: String) -> Int {
            if let lane = lanes[branch] { return lane }
            let lane = lanes.count
            lanes[branch] = lane
            return lane
        }

        for raw in MermaidLines.body(source) {
            let parts = raw.split(separator: " ").map(String.init)
            guard let command = parts.first?.lowercased() else { continue }
            switch command {
            case "commit":
                column += 1
                let label = tagOrID(parts)
                commits.append(GitCommit(column: column, lane: laneFor(current), branch: current, label: label, isMerge: false))
                branchTip[current] = column
            case "branch":
                // `branch X` creates a lane but does not switch to it.
                if parts.count > 1 { _ = laneFor(parts[1]) }
            case "checkout", "switch":
                if parts.count > 1 { current = parts[1] }
            case "merge":
                column += 1
                let merged = parts.count > 1 ? parts[1] : current
                commits.append(GitCommit(column: column, lane: laneFor(current), branch: current, label: "merge \(merged)", isMerge: true))
                branchTip[current] = column
            default:
                continue
            }
        }
        return GitGraphModel(commits: commits, laneCount: max(1, lanes.count))
    }

    private static func tagOrID(_ parts: [String]) -> String? {
        for token in parts.dropFirst() {
            if token.hasPrefix("tag:") { return token.replacingOccurrences(of: "tag:", with: "").trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
            if token.hasPrefix("id:") { return token.replacingOccurrences(of: "id:", with: "").trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
        }
        return nil
    }
}

/// Renders a git graph: commits as dots on per-branch lanes, connected in order.
struct GitGraphView: View {
    let model: GitGraphModel
    let theme: MarkdownTheme

    private let columnGap: CGFloat = 48
    private let laneGap: CGFloat = 40
    private let radius: CGFloat = 7

    private let laneColors: [Color] = [
        Color(.sRGB, red: 0.20, green: 0.55, blue: 0.95),
        Color(.sRGB, red: 0.95, green: 0.55, blue: 0.20),
        Color(.sRGB, red: 0.30, green: 0.75, blue: 0.45),
        Color(.sRGB, red: 0.70, green: 0.40, blue: 0.85),
    ]

    var body: some View {
        let maxColumn = model.commits.map(\.column).max() ?? 1
        let width = CGFloat(maxColumn + 1) * columnGap + 20
        let height = CGFloat(model.laneCount) * laneGap + 30

        Canvas { context, _ in
            // Connect consecutive commits on the same branch.
            var lastByBranch: [String: CGPoint] = [:]
            for commit in model.commits {
                let point = position(commit, height: height)
                if let prev = lastByBranch[commit.branch] {
                    var path = Path(); path.move(to: prev); path.addLine(to: point)
                    context.stroke(path, with: .color(laneColor(commit.lane)), lineWidth: 2)
                }
                lastByBranch[commit.branch] = point
            }
            for commit in model.commits {
                let point = position(commit, height: height)
                let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: rect), with: .color(laneColor(commit.lane)))
                if let label = commit.label {
                    context.draw(Text(label).font(.caption2).foregroundColor(theme.textSecondary),
                                 at: CGPoint(x: point.x, y: point.y - radius - 8))
                }
            }
        }
        .diagramFrame(width: width, height: height)
    }

    private func position(_ commit: GitCommit, height: CGFloat) -> CGPoint {
        CGPoint(x: CGFloat(commit.column) * columnGap + 10,
                y: 16 + CGFloat(commit.lane) * laneGap)
    }

    private func laneColor(_ lane: Int) -> Color { laneColors[lane % laneColors.count] }
}
