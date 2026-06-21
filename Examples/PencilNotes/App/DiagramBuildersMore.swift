import SwiftUI
import SwiftMarkdownEngine

// Round-3 visual builders completing coverage of all Mermaid types: class, state, ER, gitGraph,
// journey, timeline. Same pattern as the others: decompose the block's Mermaid source into an
// editable model and serialize a fresh model back to a ```mermaid block (live preview above).

// MARK: - Class diagram

struct ClassDiagramBuilder: View {
    @Binding var markdown: String
    let theme: MarkdownTheme

    enum Rel: String, CaseIterable, Identifiable {
        case inheritance = "inherits", composition = "composes", aggregation = "aggregates", association = "associates", dependency = "depends"
        var id: String { rawValue }
        var op: String {
            switch self {
            case .inheritance: return "<|--"
            case .composition: return "*--"
            case .aggregation: return "o--"
            case .association: return "-->"
            case .dependency: return "..>"
            }
        }
    }

    struct ClassBox: Identifiable, Equatable { let id = UUID(); var name: String; var members: String }
    struct Relation: Identifiable, Equatable { let id = UUID(); var from: String; var to: String; var rel: Rel }

    @State private var classes: [ClassBox] = []
    @State private var relations: [Relation] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            builderSection("Classes", theme: theme) {
                ForEach($classes) { $c in
                    HStack(spacing: 6) {
                        builderField("Name", text: $c.name, theme: theme).frame(width: 90)
                        builderField("members, comma-separated", text: $c.members, theme: theme)
                        builderTrash { classes.removeAll { $0.id == c.id } }
                    }
                }
                builderAdd("Class", theme: theme) { classes.append(ClassBox(name: "Class", members: "")) }
            }
            builderSection("Relationships", theme: theme) {
                ForEach($relations) { $r in
                    HStack(spacing: 6) {
                        classPicker(selection: $r.from)
                        Picker("", selection: $r.rel) { ForEach(Rel.allCases) { Text($0.rawValue).tag($0) } }
                            .pickerStyle(.menu).tint(theme.accent).labelsHidden()
                        classPicker(selection: $r.to)
                        builderTrash { relations.removeAll { $0.id == r.id } }
                    }
                }
                builderAdd("Relationship", theme: theme) {
                    let n = classes.map(\.name)
                    relations.append(Relation(from: n.first ?? "", to: n.dropFirst().first ?? n.first ?? "", rel: .association))
                }.disabled(classes.isEmpty)
            }
        }
        .onAppear(perform: decompose)
        .onChange(of: classes) { _ in recompose() }
        .onChange(of: relations) { _ in recompose() }
    }

    private func classPicker(selection: Binding<String>) -> some View {
        Picker("", selection: selection) { ForEach(classes.map(\.name), id: \.self) { Text($0).tag($0) } }
            .pickerStyle(.menu).tint(theme.accent).labelsHidden()
    }

    private func decompose() {
        let source = mermaidSource(from: markdown)
        var boxes: [ClassBox] = []
        var rels: [Relation] = []
        func ensure(_ name: String) { if !boxes.contains(where: { $0.name == name }), !name.isEmpty { boxes.append(ClassBox(name: name, members: "")) } }
        func addMember(_ cls: String, _ m: String) {
            ensure(cls)
            if let i = boxes.firstIndex(where: { $0.name == cls }) {
                boxes[i].members += boxes[i].members.isEmpty ? m : ", \(m)"
            }
        }
        let connectors: [(String, Rel)] = [("<|--", .inheritance), ("*--", .composition), ("o--", .aggregation), ("..>", .dependency), ("-->", .association)]
        for line in source.split(separator: "\n").map({ $0.trimmingCharacters(in: .whitespaces) }) {
            if line.lowercased().hasPrefix("classdiagram") || line.isEmpty { continue }
            if line.hasPrefix("class ") { ensure(String(line.dropFirst(6)).split(separator: " ").first.map(String.init) ?? ""); continue }
            if let (op, rel) = connectors.first(where: { line.contains($0.0) }) {
                let sides = line.components(separatedBy: op)
                if sides.count == 2 {
                    let from = sides[0].trimmingCharacters(in: .whitespaces)
                    var to = sides[1].trimmingCharacters(in: .whitespaces)
                    if let colon = to.firstIndex(of: ":") { to = String(to[..<colon]).trimmingCharacters(in: .whitespaces) }
                    ensure(from); ensure(to)
                    rels.append(Relation(from: from, to: to, rel: rel))
                }
                continue
            }
            if let colon = line.firstIndex(of: ":") {
                addMember(String(line[..<colon]).trimmingCharacters(in: .whitespaces),
                          String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces))
            }
        }
        classes = boxes; relations = rels
    }

    private func recompose() {
        var lines = ["classDiagram"]
        for c in classes {
            lines.append("  class \(c.name)")
            for m in c.members.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespaces) }) where !m.isEmpty {
                lines.append("  \(c.name) : \(m)")
            }
        }
        for r in relations where !r.from.isEmpty && !r.to.isEmpty {
            lines.append("  \(r.from) \(r.rel.op) \(r.to)")
        }
        markdown = mermaidBlock(lines.joined(separator: "\n"))
    }
}

// MARK: - State diagram

struct StateDiagramBuilder: View {
    @Binding var markdown: String
    let theme: MarkdownTheme

    struct Transition: Identifiable, Equatable { let id = UUID(); var from: String; var to: String; var label: String }
    @State private var transitions: [Transition] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Use [*] for start/end").font(.caption2).foregroundStyle(theme.textSecondary)
            ForEach($transitions) { $t in
                HStack(spacing: 6) {
                    builderField("from", text: $t.from, theme: theme).frame(width: 80)
                    Image(systemName: "arrow.right").foregroundStyle(theme.textSecondary)
                    builderField("to", text: $t.to, theme: theme).frame(width: 80)
                    builderField("label", text: $t.label, theme: theme)
                    builderTrash { transitions.removeAll { $0.id == t.id } }
                }
            }
            builderAdd("Transition", theme: theme) { transitions.append(Transition(from: "[*]", to: "State", label: "")) }
        }
        .onAppear(perform: decompose)
        .onChange(of: transitions) { _ in recompose() }
    }

    private func decompose() {
        let source = mermaidSource(from: markdown)
        var found: [Transition] = []
        for line in source.split(separator: "\n").map({ $0.trimmingCharacters(in: .whitespaces) }) {
            if line.lowercased().hasPrefix("statediagram") || line.isEmpty || line.hasPrefix("state ") { continue }
            guard let arrow = line.range(of: "-->") else { continue }
            let from = String(line[..<arrow.lowerBound]).trimmingCharacters(in: .whitespaces)
            var rest = String(line[arrow.upperBound...]).trimmingCharacters(in: .whitespaces)
            var label = ""
            if let colon = rest.firstIndex(of: ":") {
                label = String(rest[rest.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                rest = String(rest[..<colon]).trimmingCharacters(in: .whitespaces)
            }
            found.append(Transition(from: from, to: rest, label: label))
        }
        transitions = found
    }

    private func recompose() {
        var lines = ["stateDiagram-v2"]
        for t in transitions where !t.from.isEmpty && !t.to.isEmpty {
            lines.append("  \(t.from) --> \(t.to)" + (t.label.isEmpty ? "" : " : \(t.label)"))
        }
        markdown = mermaidBlock(lines.joined(separator: "\n"))
    }
}

// MARK: - ER diagram

struct ERDiagramBuilder: View {
    @Binding var markdown: String
    let theme: MarkdownTheme

    enum Kind: String, CaseIterable, Identifiable {
        case oneToOne = "1–1", oneToMany = "1–many", manyToOne = "many–1", manyToMany = "many–many"
        var id: String { rawValue }
        var cards: (String, String) {
            switch self {
            case .oneToOne: return ("||", "||")
            case .oneToMany: return ("||", "o{")
            case .manyToOne: return ("}o", "||")
            case .manyToMany: return ("}o", "o{")
            }
        }
    }

    struct Relation: Identifiable, Equatable { let id = UUID(); var left: String; var right: String; var kind: Kind; var label: String }
    @State private var relations: [Relation] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach($relations) { $r in
                HStack(spacing: 6) {
                    builderField("Entity", text: $r.left, theme: theme).frame(width: 84)
                    Picker("", selection: $r.kind) { ForEach(Kind.allCases) { Text($0.rawValue).tag($0) } }
                        .pickerStyle(.menu).tint(theme.accent).labelsHidden()
                    builderField("Entity", text: $r.right, theme: theme).frame(width: 84)
                    builderField("label", text: $r.label, theme: theme)
                    builderTrash { relations.removeAll { $0.id == r.id } }
                }
            }
            builderAdd("Relationship", theme: theme) { relations.append(Relation(left: "A", right: "B", kind: .oneToMany, label: "has")) }
        }
        .onAppear(perform: decompose)
        .onChange(of: relations) { _ in recompose() }
    }

    private func decompose() {
        let source = mermaidSource(from: markdown)
        var found: [Relation] = []
        for line in source.split(separator: "\n").map({ $0.trimmingCharacters(in: .whitespaces) }) {
            guard line.contains("--"), let dashes = line.range(of: "--") else { continue }
            let left = String(line[..<dashes.lowerBound]).trimmingCharacters(in: .whitespaces)
            var right = String(line[dashes.upperBound...]).trimmingCharacters(in: .whitespaces)
            var label = ""
            if let colon = right.firstIndex(of: ":") {
                label = String(right[right.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                right = String(right[..<colon]).trimmingCharacters(in: .whitespaces)
            }
            let lp = left.split(separator: " "); let rp = right.split(separator: " ")
            guard let lName = lp.first, let rName = rp.last else { continue }
            let lCard = lp.count > 1 ? String(lp.last!) : "||"
            let rCard = rp.count > 1 ? String(rp.first!) : "o{"
            let kind = Kind.allCases.first { $0.cards == (lCard, rCard) } ?? .manyToMany
            found.append(Relation(left: String(lName), right: String(rName), kind: kind, label: label))
        }
        relations = found
    }

    private func recompose() {
        var lines = ["erDiagram"]
        for r in relations where !r.left.isEmpty && !r.right.isEmpty {
            let (lc, rc) = r.kind.cards
            lines.append("  \(r.left) \(lc)--\(rc) \(r.right) : \(r.label.isEmpty ? "relates" : r.label)")
        }
        markdown = mermaidBlock(lines.joined(separator: "\n"))
    }
}

// MARK: - Git graph

struct GitGraphBuilder: View {
    @Binding var markdown: String
    let theme: MarkdownTheme

    enum Op: String, CaseIterable, Identifiable {
        case commit = "Commit", tagged = "Tagged commit", branch = "Branch", checkout = "Checkout", merge = "Merge"
        var id: String { rawValue }
        var needsValue: Bool { self != .commit }
    }

    struct Operation: Identifiable, Equatable { let id = UUID(); var op: Op; var value: String }
    @State private var ops: [Operation] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach($ops) { $o in
                HStack(spacing: 6) {
                    Picker("", selection: $o.op) { ForEach(Op.allCases) { Text($0.rawValue).tag($0) } }
                        .pickerStyle(.menu).tint(theme.accent).labelsHidden()
                    if o.op.needsValue {
                        builderField(o.op == .tagged ? "tag" : "name", text: $o.value, theme: theme)
                    }
                    builderTrash { ops.removeAll { $0.id == o.id } }
                }
            }
            builderAdd("Operation", theme: theme) { ops.append(Operation(op: .commit, value: "")) }
        }
        .onAppear(perform: decompose)
        .onChange(of: ops) { _ in recompose() }
    }

    private func decompose() {
        let source = mermaidSource(from: markdown)
        var found: [Operation] = []
        for line in source.split(separator: "\n").map({ $0.trimmingCharacters(in: .whitespaces) }) {
            let toks = line.split(separator: " ")
            guard let cmd = toks.first?.lowercased() else { continue }
            switch cmd {
            case "commit":
                if let tag = toks.first(where: { $0.hasPrefix("tag:") }) {
                    found.append(Operation(op: .tagged, value: String(tag.dropFirst(4)).trimmingCharacters(in: CharacterSet(charactersIn: "\""))))
                } else { found.append(Operation(op: .commit, value: "")) }
            case "branch": found.append(Operation(op: .branch, value: toks.count > 1 ? String(toks[1]) : ""))
            case "checkout", "switch": found.append(Operation(op: .checkout, value: toks.count > 1 ? String(toks[1]) : ""))
            case "merge": found.append(Operation(op: .merge, value: toks.count > 1 ? String(toks[1]) : ""))
            default: break
            }
        }
        ops = found
    }

    private func recompose() {
        var lines = ["gitGraph"]
        for o in ops {
            switch o.op {
            case .commit: lines.append("  commit")
            case .tagged: lines.append("  commit tag:\"\(o.value)\"")
            case .branch: lines.append("  branch \(o.value)")
            case .checkout: lines.append("  checkout \(o.value)")
            case .merge: lines.append("  merge \(o.value)")
            }
        }
        markdown = mermaidBlock(lines.joined(separator: "\n"))
    }
}

// MARK: - Journey

struct JourneyBuilder: View {
    @Binding var markdown: String
    let theme: MarkdownTheme

    struct Task: Identifiable, Equatable { let id = UUID(); var section: String; var label: String; var score: String; var actors: String }
    @State private var title: String = ""
    @State private var tasks: [Task] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            builderField("Title", text: $title, theme: theme)
            ForEach($tasks) { $t in
                HStack(spacing: 6) {
                    builderField("Section", text: $t.section, theme: theme).frame(width: 80)
                    builderField("Task", text: $t.label, theme: theme)
                    builderField("1-5", text: $t.score, theme: theme).frame(width: 40)
                    builderField("Actors", text: $t.actors, theme: theme).frame(width: 80)
                    builderTrash { tasks.removeAll { $0.id == t.id } }
                }
            }
            builderAdd("Step", theme: theme) { tasks.append(Task(section: tasks.last?.section ?? "Section", label: "Step", score: "3", actors: "Me")) }
        }
        .onAppear(perform: decompose)
        .onChange(of: title) { _ in recompose() }
        .onChange(of: tasks) { _ in recompose() }
    }

    private func decompose() {
        let source = mermaidSource(from: markdown)
        var section = ""
        var found: [Task] = []
        for line in source.split(separator: "\n").map({ $0.trimmingCharacters(in: .whitespaces) }) {
            if line.lowercased() == "journey" { continue }
            if line.hasPrefix("title ") { title = String(line.dropFirst(6)); continue }
            if line.hasPrefix("section ") { section = String(line.dropFirst(8)); continue }
            let parts = line.split(separator: ":", maxSplits: 2).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count >= 2, Int(parts[1]) != nil else { continue }
            found.append(Task(section: section, label: parts[0], score: parts[1], actors: parts.count > 2 ? parts[2] : ""))
        }
        tasks = found
    }

    private func recompose() {
        var lines = ["journey"]
        if !title.isEmpty { lines.append("  title \(title)") }
        var last: String?
        for t in tasks {
            if t.section != last { lines.append("  section \(t.section)"); last = t.section }
            lines.append("  \(t.label): \(Int(t.score) ?? 3): \(t.actors)")
        }
        markdown = mermaidBlock(lines.joined(separator: "\n"))
    }
}

// MARK: - Timeline

struct TimelineBuilder: View {
    @Binding var markdown: String
    let theme: MarkdownTheme

    struct Entry: Identifiable, Equatable { let id = UUID(); var period: String; var events: String }
    @State private var title: String = ""
    @State private var entries: [Entry] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            builderField("Title", text: $title, theme: theme)
            ForEach($entries) { $e in
                HStack(spacing: 6) {
                    builderField("Period", text: $e.period, theme: theme).frame(width: 90)
                    builderField("events, comma-separated", text: $e.events, theme: theme)
                    builderTrash { entries.removeAll { $0.id == e.id } }
                }
            }
            builderAdd("Period", theme: theme) { entries.append(Entry(period: "Period", events: "Event")) }
        }
        .onAppear(perform: decompose)
        .onChange(of: title) { _ in recompose() }
        .onChange(of: entries) { _ in recompose() }
    }

    private func decompose() {
        let source = mermaidSource(from: markdown)
        var found: [Entry] = []
        for line in source.split(separator: "\n").map({ $0.trimmingCharacters(in: .whitespaces) }) {
            if line.lowercased() == "timeline" || line.hasPrefix("section ") { continue }
            if line.hasPrefix("title ") { title = String(line.dropFirst(6)); continue }
            let parts = line.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            guard let period = parts.first, !period.isEmpty else { continue }
            found.append(Entry(period: period, events: parts.dropFirst().joined(separator: ", ")))
        }
        entries = found
    }

    private func recompose() {
        var lines = ["timeline"]
        if !title.isEmpty { lines.append("  title \(title)") }
        for e in entries where !e.period.isEmpty {
            let evs = e.events.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            lines.append("  \(e.period)" + (evs.isEmpty ? "" : " : " + evs.joined(separator: " : ")))
        }
        markdown = mermaidBlock(lines.joined(separator: "\n"))
    }
}
