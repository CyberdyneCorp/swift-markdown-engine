import Foundation

// Serializes the document model back to Markdown. The parser is Markdown → model; this is
// the reverse, used by editing surfaces so visual edits persist as Markdown. The goal is
// round-trip *fidelity of the model* (parse → serialize → parse yields an equal document),
// not byte-identical source — emphasis is normalized to `*`/`**`, whitespace is reflowed, etc.

public extension MarkdownDocument {
    /// The document serialized back to a Markdown string.
    func markdown() -> String {
        var parts: [String] = []
        if let frontmatter, !frontmatter.raw.isEmpty {
            parts.append("---\n\(frontmatter.raw)\n---")
        }
        parts.append(MarkdownSerializer.blocks(blocks))
        // Footnote definitions are kept out of `blocks`; emit them so they round-trip.
        let notes = footnotes
            .sorted { $0.key < $1.key }
            .map { MarkdownSerializer.footnoteDefinition(label: $0.key, blocks: $0.value) }
        if !notes.isEmpty { parts.append(notes.joined(separator: "\n\n")) }
        return parts.filter { !$0.isEmpty }.joined(separator: "\n\n") + "\n"
    }
}

public extension BlockNode {
    /// This block serialized to its Markdown fragment.
    func markdown() -> String { MarkdownSerializer.block(self) }
}

public extension InlineNode {
    /// This inline node serialized to Markdown.
    func markdown() -> String { MarkdownSerializer.inline(self) }
}

enum MarkdownSerializer {
    // MARK: - Blocks

    static func blocks(_ nodes: [BlockNode]) -> String {
        nodes.map(block).joined(separator: "\n\n")
    }

    static func block(_ node: BlockNode) -> String {
        switch node.kind {
        case .heading(let level, let nodes):
            return String(repeating: "#", count: max(1, min(6, level))) + " " + inlines(nodes)
        case .paragraph(let inlines):
            return self.inlines(inlines)
        case .blockQuote(let blocks):
            return quotePrefixed(self.blocks(blocks), header: nil)
        case .thematicBreak:
            return "---"
        case .codeBlock(let language, let content):
            return "```\(language ?? "")\n\(content)\n```"
        case .mermaid(let source):
            return "```mermaid\n\(source)\n```"
        case .mathBlock(let body):
            return "$$\n\(body)\n$$"
        case .list(let list):
            return self.list(list)
        case .table(let table):
            return self.table(table)
        case .htmlBlock(let html):
            return html
        case .footnoteDefinition(let label, let blocks):
            return footnoteDefinition(label: label, blocks: blocks)
        case .callout(let kind, let title, let blocks):
            let header = "[!\(kind.rawValue.uppercased())]" + (title.map { " \($0)" } ?? "")
            return quotePrefixed(self.blocks(blocks), header: header)
        }
    }

    // MARK: - Lists

    static func list(_ list: MarkdownList) -> String {
        var lines: [String] = []
        var number = list.marker.startNumber
        for item in list.items {
            let marker: String
            switch list.marker {
            case .bullet: marker = "- "
            case .ordered: marker = "\(number). "; number += 1
            }
            // Checkbox carries its own trailing space; strip a single leading space the parser
            // may have left in the body so the result is exactly `- [x] text` either way (works
            // for both re-parsed and programmatically-built task items).
            let checkbox = item.checkbox.map { $0 == .checked ? "[x] " : "[ ] " } ?? ""
            // Join the item's own blocks with single newlines in a tight list so a nested
            // list immediately follows its paragraph (a blank line would un-nest it).
            let body = item.blocks.map(block).joined(separator: list.isTight ? "\n" : "\n\n")
            let indent = String(repeating: " ", count: marker.count)
            let itemLines = body.split(separator: "\n", omittingEmptySubsequences: false).enumerated().map {
                offset, raw -> String in
                guard offset == 0 else { return raw.isEmpty ? "" : indent + raw }
                var first = String(raw)
                if item.checkbox != nil, first.hasPrefix(" ") { first.removeFirst() }
                return marker + checkbox + first
            }
            lines.append(itemLines.joined(separator: "\n"))
        }
        return lines.joined(separator: list.isTight ? "\n" : "\n\n")
    }

    // MARK: - Tables

    static func table(_ table: MarkdownTable) -> String {
        func row(_ cells: [[InlineNode]]) -> String {
            "| " + cells.map { inlines($0) }.joined(separator: " | ") + " |"
        }
        func divider(_ a: MarkdownTable.Alignment) -> String {
            switch a {
            case .none: return "---"
            case .left: return ":---"
            case .center: return ":---:"
            case .right: return "---:"
            }
        }
        var out = [row(table.header)]
        out.append("| " + table.alignments.map(divider).joined(separator: " | ") + " |")
        out.append(contentsOf: table.rows.map(row))
        return out.joined(separator: "\n")
    }

    // MARK: - Quote / callout / footnote helpers

    private static func quotePrefixed(_ content: String, header: String?) -> String {
        var lines = header.map { [$0] } ?? []
        lines.append(contentsOf: content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init))
        return lines.map { $0.isEmpty ? ">" : "> " + $0 }.joined(separator: "\n")
    }

    static func footnoteDefinition(label: String, blocks: [BlockNode]) -> String {
        let body = self.blocks(blocks)
        let lines = body.split(separator: "\n", omittingEmptySubsequences: false).enumerated().map {
            offset, line in offset == 0 ? "[^\(label)]: \(line)" : (line.isEmpty ? "" : "    " + line)
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Inlines

    static func inlines(_ nodes: [InlineNode]) -> String {
        nodes.map(inline).joined()
    }

    static func inline(_ node: InlineNode) -> String {
        switch node.kind {
        case .text(let s): return s
        case .softBreak: return "\n"
        case .lineBreak: return "  \n"
        case .code(let s): return wrapCode(s)
        case .emphasis(let children): return "*" + inlines(children) + "*"
        case .strong(let children): return "**" + inlines(children) + "**"
        case .strikethrough(let children): return "~~" + inlines(children) + "~~"
        case .link(let destination, let title, let children):
            return "[\(inlines(children))](\(destination)\(titleSuffix(title)))"
        case .image(let source, let title, let alt):
            return "![\(alt)](\(source)\(titleSuffix(title)))"
        case .autolink(let url, _): return "<\(url)>"
        case .wikiLink(let target, let display):
            return "[[\(target)\(display.map { "|\($0)" } ?? "")]]"
        case .footnoteReference(let label): return "[^\(label)]"
        case .inlineMath(let body): return "$\(body)$"
        case .inlineHTML(let html): return html
        }
    }

    private static func titleSuffix(_ title: String?) -> String {
        guard let title, !title.isEmpty else { return "" }
        return " \"\(title)\""
    }

    /// Wraps an inline code span, widening the backtick fence if the content contains backticks.
    private static func wrapCode(_ s: String) -> String {
        var fence = "`"
        while s.contains(fence) { fence += "`" }
        let pad = (s.hasPrefix("`") || s.hasSuffix("`")) ? " " : ""
        return fence + pad + s + pad + fence
    }
}

private extension MarkdownList.Marker {
    var startNumber: Int {
        if case .ordered(let start) = self { return start }
        return 1
    }
}
