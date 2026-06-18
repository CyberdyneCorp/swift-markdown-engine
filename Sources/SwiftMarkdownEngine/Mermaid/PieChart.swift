import SwiftUI

struct PieSlice: Equatable {
    let label: String
    let value: Double
}

struct PieChartModel: Equatable {
    let title: String?
    let slices: [PieSlice]
    var total: Double { slices.reduce(0) { $0 + $1.value } }
}

enum PieChartParser {
    static func parse(_ source: String) -> PieChartModel {
        let firstLine = source.split(separator: "\n").first.map(String.init) ?? ""
        var title: String?
        if let range = firstLine.range(of: "title ") {
            title = String(firstLine[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        var slices: [PieSlice] = []
        for line in MermaidLines.body(source) {
            // Expected: "Label" : value
            guard let colon = line.lastIndex(of: ":") else { continue }
            let labelPart = line[..<colon].trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
            let valuePart = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            guard let value = Double(valuePart), !labelPart.isEmpty else { continue }
            slices.append(PieSlice(label: labelPart, value: value))
        }
        return PieChartModel(title: title, slices: slices)
    }
}

/// Renders a pie chart with wedges and a percentage legend.
struct PieChartView: View {
    let model: PieChartModel
    let theme: MarkdownTheme

    private let palette: [Color] = [
        Color(.sRGB, red: 0.20, green: 0.55, blue: 0.95),
        Color(.sRGB, red: 0.95, green: 0.55, blue: 0.20),
        Color(.sRGB, red: 0.30, green: 0.75, blue: 0.45),
        Color(.sRGB, red: 0.85, green: 0.30, blue: 0.45),
        Color(.sRGB, red: 0.60, green: 0.40, blue: 0.85),
        Color(.sRGB, red: 0.40, green: 0.70, blue: 0.80),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = model.title { Text(title).font(.headline).foregroundStyle(theme.textPrimary) }
            HStack(alignment: .center, spacing: 16) {
                wedges.frame(width: 140, height: 140)
                legend
            }
        }
    }

    private var wedges: some View {
        Canvas { context, size in
            let total = model.total
            guard total > 0 else { return }
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 2
            var startAngle = -90.0
            for (index, slice) in model.slices.enumerated() {
                let sweep = slice.value / total * 360
                var path = Path()
                path.move(to: center)
                path.addArc(center: center, radius: radius,
                            startAngle: .degrees(startAngle), endAngle: .degrees(startAngle + sweep), clockwise: false)
                path.closeSubpath()
                context.fill(path, with: .color(palette[index % palette.count]))
                startAngle += sweep
            }
        }
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(model.slices.enumerated()), id: \.offset) { index, slice in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2).fill(palette[index % palette.count]).frame(width: 12, height: 12)
                    Text("\(slice.label) (\(percent(slice.value)))")
                        .font(.caption).foregroundStyle(theme.textPrimary)
                }
            }
        }
    }

    private func percent(_ value: Double) -> String {
        guard model.total > 0 else { return "0%" }
        return "\(Int((value / model.total * 100).rounded()))%"
    }
}
