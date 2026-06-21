import SwiftUI
import SwiftMarkdownEngine

// Phase-2 visual builders for the two most form-friendly Mermaid diagrams: pie charts and
// flowcharts. Each decomposes the block's Mermaid source into an editable model and serializes
// a fresh model back to a ```mermaid fenced block. The rendered diagram above is the live preview.

// MARK: - Shared helpers

private func mermaidSource(from markdown: String) -> String {
    guard case .mermaid(let source)? = MarkdownParser().parse(markdown).blocks.first?.kind else { return "" }
    return source
}

private func mermaidBlock(_ source: String) -> String { "```mermaid\n\(source)\n```" }

// MARK: - Pie chart

struct PieChartBuilder: View {
    @Binding var markdown: String
    let theme: MarkdownTheme

    struct Slice: Identifiable, Equatable { let id = UUID(); var label: String; var value: String }

    @State private var title: String = ""
    @State private var slices: [Slice] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            field("Title", text: $title)
            ForEach($slices) { $slice in
                HStack(spacing: 8) {
                    field("Label", text: $slice.label)
                    field("Value", text: $slice.value)
                        .frame(width: 80)
                        .keyboardType(.decimalPad)
                    trash { slices.removeAll { $0.id == slice.id } }
                }
            }
            addButton("Slice") { slices.append(Slice(label: "Slice", value: "1")) }
        }
        .onAppear(perform: decompose)
        .onChange(of: title) { _ in recompose() }
        .onChange(of: slices) { _ in recompose() }
    }

    private func decompose() {
        let source = mermaidSource(from: markdown)
        var found: [Slice] = []
        for (i, rawLine) in source.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if i == 0 || line.lowercased().hasPrefix("pie") {
                if let r = line.range(of: "title ") { title = String(line[r.upperBound...]).trimmingCharacters(in: .whitespaces) }
                continue
            }
            guard let colon = line.lastIndex(of: ":") else { continue }
            let label = line[..<colon].trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            if !label.isEmpty { found.append(Slice(label: label, value: value)) }
        }
        slices = found
    }

    private func recompose() {
        var lines = ["pie" + (title.isEmpty ? "" : " title \(title)")]
        lines += slices.map { "  \"\($0.label)\" : \(Double($0.value) ?? 0)" }
        markdown = mermaidBlock(lines.joined(separator: "\n"))
    }

    private func field(_ p: String, text: Binding<String>) -> some View { builderField(p, text: text, theme: theme) }
    private func trash(_ action: @escaping () -> Void) -> some View { builderTrash(action) }
    private func addButton(_ label: String, _ action: @escaping () -> Void) -> some View { builderAdd(label, theme: theme, action: action) }
}

// MARK: - Flowchart

struct FlowchartBuilder: View {
    @Binding var markdown: String
    let theme: MarkdownTheme

    enum Shape: String, CaseIterable, Identifiable {
        case rectangle = "Rectangle", rounded = "Rounded", stadium = "Stadium", circle = "Circle", diamond = "Diamond"
        var id: String { rawValue }
        var delimiters: (String, String) {
            switch self {
            case .rectangle: return ("[", "]")
            case .rounded: return ("(", ")")
            case .stadium: return ("([", "])")
            case .circle: return ("((", "))")
            case .diamond: return ("{", "}")
            }
        }
    }

    struct Node: Identifiable, Equatable { let id = UUID(); var key: String; var label: String; var shape: Shape }
    struct Edge: Identifiable, Equatable { let id = UUID(); var from: String; var to: String; var label: String }

    private static let directions = ["LR", "TD", "TB", "RL", "BT"]

    @State private var direction = "LR"
    @State private var nodes: [Node] = []
    @State private var edges: [Edge] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Direction").font(.caption.weight(.semibold)).foregroundStyle(theme.textSecondary)
                Picker("Direction", selection: $direction) {
                    ForEach(Self.directions, id: \.self) { Text($0).tag($0) }
                }.pickerStyle(.menu).tint(theme.accent)
                Spacer()
            }

            section("Nodes") {
                ForEach($nodes) { $node in
                    HStack(spacing: 6) {
                        field("id", text: $node.key).frame(width: 64)
                        field("label", text: $node.label)
                        Picker("", selection: $node.shape) {
                            ForEach(Shape.allCases) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.menu).tint(theme.accent).labelsHidden()
                        trash { nodes.removeAll { $0.id == node.id } }
                    }
                }
                addButton("Node") { nodes.append(Node(key: nextKey(), label: "Node", shape: .rectangle)) }
            }

            section("Edges") {
                ForEach($edges) { $edge in
                    HStack(spacing: 6) {
                        keyPicker(selection: $edge.from)
                        Image(systemName: "arrow.right").foregroundStyle(theme.textSecondary)
                        keyPicker(selection: $edge.to)
                        field("label", text: $edge.label).frame(width: 80)
                        trash { edges.removeAll { $0.id == edge.id } }
                    }
                }
                addButton("Edge") {
                    let k = nodes.first?.key ?? ""
                    edges.append(Edge(from: k, to: nodes.dropFirst().first?.key ?? k, label: ""))
                }
                .disabled(nodes.isEmpty)
            }
        }
        .onAppear(perform: decompose)
        .onChange(of: direction) { _ in recompose() }
        .onChange(of: nodes) { _ in recompose() }
        .onChange(of: edges) { _ in recompose() }
    }

    private func keyPicker(selection: Binding<String>) -> some View {
        Picker("", selection: selection) {
            ForEach(nodes.map(\.key), id: \.self) { Text($0).tag($0) }
        }
        .pickerStyle(.menu).tint(theme.accent).labelsHidden()
    }

    private func nextKey() -> String {
        for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" where !nodes.contains(where: { $0.key == String(c) }) { return String(c) }
        return "N\(nodes.count + 1)"
    }

    // MARK: Decompose / recompose

    private func decompose() {
        let source = mermaidSource(from: markdown)
        var foundNodes: [Node] = []
        var foundEdges: [Edge] = []

        func ensure(_ key: String, _ label: String, _ shape: Shape) {
            if let i = foundNodes.firstIndex(where: { $0.key == key }) {
                if foundNodes[i].label == foundNodes[i].key, label != key { foundNodes[i].label = label; foundNodes[i].shape = shape }
            } else {
                foundNodes.append(Node(key: key, label: label, shape: shape))
            }
        }

        for (i, rawLine) in source.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            if i == 0 || line.lowercased().hasPrefix("flowchart") || line.lowercased().hasPrefix("graph") {
                let toks = line.split(separator: " ")
                if toks.count > 1, Self.directions.contains(String(toks[1]).uppercased()) { direction = String(toks[1]).uppercased() }
                continue
            }
            let parts = line.components(separatedBy: "-->")
            var prev: String?
            for part in parts {
                var token = part.trimmingCharacters(in: .whitespaces)
                var edgeLabel = ""
                if token.hasPrefix("|"), let close = token.dropFirst().firstIndex(of: "|") {
                    edgeLabel = String(token[token.index(after: token.startIndex)..<close])
                    token = String(token[token.index(after: close)...]).trimmingCharacters(in: .whitespaces)
                }
                guard !token.isEmpty else { continue }
                let (key, label, shape) = Self.parseNode(token)
                ensure(key, label, shape)
                if let from = prev { foundEdges.append(Edge(from: from, to: key, label: edgeLabel)) }
                prev = key
            }
        }
        nodes = foundNodes
        edges = foundEdges
    }

    private static func parseNode(_ token: String) -> (String, String, Shape) {
        let specs: [(String, String, Shape)] = [
            ("([", "])", .stadium), ("((", "))", .circle), ("[", "]", .rectangle), ("(", ")", .rounded), ("{", "}", .diamond),
        ]
        for (open, close, shape) in specs {
            if let r = token.range(of: open), token.hasSuffix(close) {
                let key = String(token[..<r.lowerBound]).trimmingCharacters(in: .whitespaces)
                let label = String(token[r.upperBound..<token.index(token.endIndex, offsetBy: -close.count)])
                    .trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
                if !key.isEmpty { return (key, label.isEmpty ? key : label, shape) }
            }
        }
        let key = token.trimmingCharacters(in: .whitespaces)
        return (key, key, .rectangle)
    }

    private func recompose() {
        var lines = ["flowchart \(direction)"]
        for node in nodes {
            let (open, close) = node.shape.delimiters
            if node.shape == .rectangle, node.label == node.key {
                lines.append("  \(node.key)")          // bare node
            } else {
                lines.append("  \(node.key)\(open)\(node.label)\(close)")
            }
        }
        for edge in edges where !edge.from.isEmpty && !edge.to.isEmpty {
            let arrow = edge.label.isEmpty ? "-->" : "-->|\(edge.label)|"
            lines.append("  \(edge.from) \(arrow) \(edge.to)")
        }
        markdown = mermaidBlock(lines.joined(separator: "\n"))
    }

    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(theme.textSecondary)
            content()
        }
    }
    private func field(_ p: String, text: Binding<String>) -> some View { builderField(p, text: text, theme: theme) }
    private func trash(_ action: @escaping () -> Void) -> some View { builderTrash(action) }
    private func addButton(_ label: String, _ action: @escaping () -> Void) -> some View { builderAdd(label, theme: theme, action: action) }
}

// MARK: - Small shared controls

private func builderField(_ placeholder: String, text: Binding<String>, theme: MarkdownTheme) -> some View {
    TextField(placeholder, text: text)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .padding(6)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 6))
}

private func builderTrash(_ action: @escaping () -> Void) -> some View {
    Button(role: .destructive, action: action) { Image(systemName: "trash") }
        .buttonStyle(.plain).foregroundStyle(.red).accessibilityLabel("Delete")
}

private func builderAdd(_ label: String, theme: MarkdownTheme, action: @escaping () -> Void) -> some View {
    Button(action: action) { Label(label, systemImage: "plus") }
        .buttonStyle(.plain).foregroundStyle(theme.accent).font(.system(size: 15, weight: .medium))
}
