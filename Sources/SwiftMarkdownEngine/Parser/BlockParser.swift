import Foundation

/// Parses an array of source lines into block nodes. Container blocks (block
/// quotes, list items) are parsed recursively by stripping their markers and
/// re-parsing the inner lines.
struct BlockParser {
    let referenceLinks: [String: LinkReference]
    let mathEnabled: Bool
    let wikiLinksEnabled: Bool

    private var inline: InlineParser {
        InlineParser(referenceLinks: referenceLinks, mathEnabled: mathEnabled, wikiLinksEnabled: wikiLinksEnabled)
    }

    func parse(_ lines: [SourceLine]) -> [BlockNode] {
        var blocks: [BlockNode] = []
        var i = 0
        while i < lines.count {
            let line = lines[i]
            if line.isBlank { i += 1; continue }

            if let (node, next) = parseFence(lines, i) { blocks.append(node); i = next }
            else if let (node, next) = parseMathBlock(lines, i) { blocks.append(node); i = next }
            else if let node = parseThematicBreak(line) { blocks.append(node); i += 1 }
            else if let node = parseATXHeading(line) { blocks.append(node); i += 1 }
            else if let (node, next) = parseBlockQuote(lines, i) { blocks.append(node); i = next }
            else if let (node, next) = parseList(lines, i) { blocks.append(node); i = next }
            else if let (node, next) = parseTable(lines, i) { blocks.append(node); i = next }
            else if let (node, next) = parseHTMLBlock(lines, i) { blocks.append(node); i = next }
            else { let (node, next) = parseParagraph(lines, i); blocks.append(node); i = next }
        }
        return blocks
    }

    private func range(_ lines: [SourceLine], _ from: Int, _ toInclusive: Int) -> SourceRange {
        SourceRange(lowerBound: lines[from].start, upperBound: lines[toInclusive].contentEnd)
    }

    // MARK: - Fenced code / mermaid

    private func parseFence(_ lines: [SourceLine], _ start: Int) -> (BlockNode, Int)? {
        let trimmed = lines[start].trimmedLeft
        let fenceChar: Character
        if trimmed.hasPrefix("```") { fenceChar = "`" }
        else if trimmed.hasPrefix("~~~") { fenceChar = "~" }
        else { return nil }

        let info = trimmed.drop { $0 == fenceChar }.trimmingCharacters(in: .whitespaces)
        var i = start + 1
        var content: [String] = []
        while i < lines.count {
            let candidate = lines[i].trimmedLeft
            if candidate.allSatisfy({ $0 == fenceChar }), candidate.count >= 3 { i += 1; break }
            content.append(lines[i].text)
            i += 1
        }
        let body = content.joined(separator: "\n")
        let language = info.isEmpty ? nil : String(info.split(separator: " ").first ?? "")
        let node: BlockNode
        if language?.lowercased() == "mermaid" {
            node = BlockNode(.mermaid(source: body), range: range(lines, start, min(i, lines.count) - 1))
        } else {
            node = BlockNode(.codeBlock(language: language, content: body), range: range(lines, start, min(i, lines.count) - 1))
        }
        return (node, i)
    }

    // MARK: - Block math ($$ … $$)

    private func parseMathBlock(_ lines: [SourceLine], _ start: Int) -> (BlockNode, Int)? {
        guard mathEnabled else { return nil }
        let trimmed = lines[start].trimmedLeft
        guard trimmed.hasPrefix("$$") else { return nil }

        // Single-line: $$ … $$
        let afterOpen = trimmed.dropFirst(2)
        if afterOpen.hasSuffix("$$"), afterOpen.count >= 2 {
            let body = String(afterOpen.dropLast(2)).trimmingCharacters(in: .whitespaces)
            return (BlockNode(.mathBlock(body: body), range: range(lines, start, start)), start + 1)
        }
        // Multi-line until a closing $$.
        var i = start + 1
        var content: [String] = afterOpen.isEmpty ? [] : [String(afterOpen)]
        while i < lines.count {
            let t = lines[i].trimmedLeft
            if t.hasSuffix("$$") { content.append(String(t.dropLast(2))); i += 1; break }
            content.append(lines[i].text); i += 1
        }
        let body = content.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return (BlockNode(.mathBlock(body: body), range: range(lines, start, min(i, lines.count) - 1)), i)
    }

    // MARK: - Thematic break

    private func parseThematicBreak(_ line: SourceLine) -> BlockNode? {
        let stripped = line.trimmedLeft.filter { $0 != " " }
        guard stripped.count >= 3 else { return nil }
        for marker: Character in ["*", "-", "_"] where stripped.allSatisfy({ $0 == marker }) {
            return BlockNode(.thematicBreak, range: SourceRange(lowerBound: line.start, upperBound: line.contentEnd))
        }
        return nil
    }

    // MARK: - ATX heading

    private func parseATXHeading(_ line: SourceLine) -> BlockNode? {
        let trimmed = line.trimmedLeft
        guard trimmed.hasPrefix("#") else { return nil }
        let hashes = trimmed.prefix { $0 == "#" }
        let level = hashes.count
        guard level >= 1, level <= 6 else { return nil }
        let rest = trimmed.dropFirst(level)
        guard rest.isEmpty || rest.first == " " else { return nil }
        var text = rest.trimmingCharacters(in: .whitespaces)
        // Strip optional closing hashes.
        while text.hasSuffix("#") { text = String(text.dropLast()) }
        text = text.trimmingCharacters(in: .whitespaces)
        return BlockNode(.heading(level: level, inlines: inline.parse(text)),
                         range: SourceRange(lowerBound: line.start, upperBound: line.contentEnd))
    }

    // MARK: - Block quote / callout

    private func parseBlockQuote(_ lines: [SourceLine], _ start: Int) -> (BlockNode, Int)? {
        guard lines[start].trimmedLeft.hasPrefix(">") else { return nil }
        var i = start
        var inner: [SourceLine] = []
        while i < lines.count, lines[i].trimmedLeft.hasPrefix(">") {
            let stripped = stripQuoteMarker(lines[i])
            inner.append(stripped)
            i += 1
        }
        // Callout detection: first inner line "[!TYPE] optional title".
        if let first = inner.first, let callout = parseCalloutHeader(first.text) {
            let bodyLines = Array(inner.dropFirst())
            let blocks = BlockParser(referenceLinks: referenceLinks, mathEnabled: mathEnabled, wikiLinksEnabled: wikiLinksEnabled).parse(bodyLines)
            return (BlockNode(.callout(kind: callout.kind, title: callout.title, blocks: blocks),
                              range: range(lines, start, i - 1)), i)
        }
        let blocks = BlockParser(referenceLinks: referenceLinks, mathEnabled: mathEnabled, wikiLinksEnabled: wikiLinksEnabled).parse(inner)
        return (BlockNode(.blockQuote(blocks), range: range(lines, start, i - 1)), i)
    }

    private func stripQuoteMarker(_ line: SourceLine) -> SourceLine {
        var text = String(line.trimmedLeft)
        let removedLeading = line.text.count - text.count
        if text.hasPrefix(">") { text.removeFirst() }
        if text.hasPrefix(" ") { text.removeFirst() }
        let removed = line.text.count - text.count
        let bytes = String(line.text.prefix(removed)).utf8.count
        _ = removedLeading
        return SourceLine(text: text, start: line.start + bytes, contentEnd: line.contentEnd)
    }

    private func parseCalloutHeader(_ text: String) -> (kind: CalloutKind, title: String?)? {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard t.hasPrefix("[!"), let close = t.firstIndex(of: "]") else { return nil }
        let label = String(t[t.index(t.startIndex, offsetBy: 2)..<close])
        let title = String(t[t.index(after: close)...]).trimmingCharacters(in: .whitespaces)
        return (CalloutKind(label: label), title.isEmpty ? nil : title)
    }

    // MARK: - Lists

    private func parseList(_ lines: [SourceLine], _ start: Int) -> (BlockNode, Int)? {
        guard let firstMarker = listMarker(lines[start]) else { return nil }
        var items: [ListItem] = []
        var i = start
        var isTight = true
        let baseIndent = lines[start].indent

        while i < lines.count {
            guard let marker = listMarker(lines[i]), lines[i].indent == baseIndent,
                  marker.isOrdered == firstMarker.isOrdered else { break }
            // Gather this item's lines: the marker line plus more-indented / blank continuations.
            let itemContentIndent = marker.contentColumn
            var itemLines: [SourceLine] = [dropPrefix(lines[i], marker.markerLength)]
            i += 1
            while i < lines.count {
                if lines[i].isBlank {
                    // Peek: blank then a continuation belongs to the item (loose).
                    if i + 1 < lines.count, !lines[i + 1].isBlank, lines[i + 1].indent >= itemContentIndent, listMarker(lines[i + 1]) == nil {
                        itemLines.append(SourceLine(text: "", start: lines[i].start, contentEnd: lines[i].contentEnd))
                        isTight = false
                        i += 1
                        continue
                    }
                    break
                }
                if listMarker(lines[i]) != nil, lines[i].indent == baseIndent { break }
                if lines[i].indent >= itemContentIndent || listMarker(lines[i]) != nil {
                    itemLines.append(dropPrefix(lines[i], min(itemContentIndent, lines[i].indent)))
                    i += 1
                } else { break }
            }
            let (checkbox, contentLines) = extractCheckbox(itemLines)
            let blocks = BlockParser(referenceLinks: referenceLinks, mathEnabled: mathEnabled, wikiLinksEnabled: wikiLinksEnabled).parse(contentLines)
            items.append(ListItem(blocks: blocks, checkbox: checkbox))
            // Skip a single trailing blank between items.
            if i < lines.count, lines[i].isBlank, i + 1 < lines.count, listMarker(lines[i + 1]) != nil, lines[i + 1].indent == baseIndent {
                isTight = false
                i += 1
            }
        }

        let listMarkerKind: MarkdownList.Marker = firstMarker.isOrdered ? .ordered(start: firstMarker.start) : .bullet
        let list = MarkdownList(marker: listMarkerKind, isTight: isTight, items: items)
        return (BlockNode(.list(list), range: range(lines, start, max(start, i - 1))), i)
    }

    private func extractCheckbox(_ lines: [SourceLine]) -> (ListItem.Checkbox?, [SourceLine]) {
        guard let first = lines.first else { return (nil, lines) }
        let t = first.trimmedLeft
        if t.hasPrefix("[ ] ") || t == "[ ]" {
            return (.unchecked, [dropPrefix(first, first.text.count - String(t.dropFirst(3)).count)] + lines.dropFirst())
        }
        if t.hasPrefix("[x] ") || t.hasPrefix("[X] ") || t == "[x]" || t == "[X]" {
            return (.checked, [dropPrefix(first, first.text.count - String(t.dropFirst(3)).count)] + lines.dropFirst())
        }
        return (nil, lines)
    }

    private struct Marker { let isOrdered: Bool; let start: Int; let markerLength: Int; let contentColumn: Int }

    private func listMarker(_ line: SourceLine) -> Marker? {
        let indent = line.indent
        let t = line.trimmedLeft
        guard let first = t.first else { return nil }
        if first == "-" || first == "+" || first == "*" {
            guard t.count >= 2, t[t.index(after: t.startIndex)] == " " else { return nil }
            return Marker(isOrdered: false, start: 1, markerLength: indent + 2, contentColumn: indent + 2)
        }
        // Ordered: digits followed by . or )
        let digits = t.prefix { $0.isNumber }
        if !digits.isEmpty, digits.count <= 9 {
            let afterDigits = t.dropFirst(digits.count)
            if let delim = afterDigits.first, delim == "." || delim == ")",
               afterDigits.count >= 2, afterDigits[afterDigits.index(after: afterDigits.startIndex)] == " " {
                let len = indent + digits.count + 2
                return Marker(isOrdered: true, start: Int(digits) ?? 1, markerLength: len, contentColumn: len)
            }
        }
        return nil
    }

    private func dropPrefix(_ line: SourceLine, _ count: Int) -> SourceLine {
        let n = min(count, line.text.count)
        let prefix = String(line.text.prefix(n))
        let bytes = prefix.utf8.count
        return SourceLine(text: String(line.text.dropFirst(n)), start: line.start + bytes, contentEnd: line.contentEnd)
    }

    // MARK: - GFM tables

    private func parseTable(_ lines: [SourceLine], _ start: Int) -> (BlockNode, Int)? {
        guard start + 1 < lines.count else { return nil }
        let headerLine = lines[start].text
        let delimLine = lines[start + 1].text
        guard headerLine.contains("|"), isDelimiterRow(delimLine) else { return nil }

        let alignments = parseAlignments(delimLine)
        let header = splitRow(headerLine).map { inline.parse($0) }
        var rows: [[[InlineNode]]] = []
        var i = start + 2
        while i < lines.count, lines[i].text.contains("|"), !lines[i].isBlank {
            rows.append(splitRow(lines[i].text).map { inline.parse($0) })
            i += 1
        }
        let table = MarkdownTable(alignments: alignments, header: header, rows: rows)
        return (BlockNode(.table(table), range: range(lines, start, i - 1)), i)
    }

    private func isDelimiterRow(_ line: String) -> Bool {
        let cells = splitRow(line)
        guard !cells.isEmpty else { return false }
        return cells.allSatisfy { cell in
            let c = cell.trimmingCharacters(in: .whitespaces)
            return !c.isEmpty && c.allSatisfy { $0 == "-" || $0 == ":" } && c.contains("-")
        }
    }

    private func parseAlignments(_ line: String) -> [MarkdownTable.Alignment] {
        splitRow(line).map { cell in
            let c = cell.trimmingCharacters(in: .whitespaces)
            let left = c.hasPrefix(":"), right = c.hasSuffix(":")
            if left && right { return .center }
            if right { return .right }
            if left { return .left }
            return .none
        }
    }

    private func splitRow(_ line: String) -> [String] {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("|") { trimmed.removeFirst() }
        if trimmed.hasSuffix("|") { trimmed.removeLast() }
        // Split on unescaped pipes.
        var cells: [String] = []
        var current = ""
        var escaped = false
        for ch in trimmed {
            if escaped { current.append(ch); escaped = false }
            else if ch == "\\" { escaped = true; current.append(ch) }
            else if ch == "|" { cells.append(current.trimmingCharacters(in: .whitespaces)); current = "" }
            else { current.append(ch) }
        }
        cells.append(current.trimmingCharacters(in: .whitespaces))
        return cells
    }

    // MARK: - HTML block

    private func parseHTMLBlock(_ lines: [SourceLine], _ start: Int) -> (BlockNode, Int)? {
        guard isHTMLBlockStart(lines[start].trimmedLeft) else { return nil }
        var i = start
        var content: [String] = []
        while i < lines.count, !lines[i].isBlank {
            content.append(lines[i].text); i += 1
        }
        return (BlockNode(.htmlBlock(content.joined(separator: "\n")), range: range(lines, start, i - 1)), i)
    }

    /// An HTML block starts with `<!`, `<?`, or `<`/`</` followed by a valid tag
    /// name. A line like `<https://…>` is an autolink, not an HTML block, because a
    /// `:` is not a legal tag-name character.
    private func isHTMLBlockStart(_ text: Substring) -> Bool {
        guard text.hasPrefix("<") else { return false }
        var rest = text.dropFirst()
        if rest.hasPrefix("!") || rest.hasPrefix("?") { return true }
        if rest.hasPrefix("/") { rest = rest.dropFirst() }
        guard let firstName = rest.first, firstName.isLetter else { return false }
        let name = rest.prefix { $0.isLetter || $0.isNumber || $0 == "-" }
        let afterName = rest.dropFirst(name.count).first
        // Valid tag terminator: whitespace, '>', '/', or end of line.
        return afterName == nil || afterName == " " || afterName == ">" || afterName == "/"
    }

    // MARK: - Paragraph (with Setext heading)

    private func parseParagraph(_ lines: [SourceLine], _ start: Int) -> (BlockNode, Int) {
        var i = start
        var content: [String] = []
        while i < lines.count, !lines[i].isBlank {
            let line = lines[i]
            // Setext heading: a paragraph followed by an underline of = or -.
            if i > start {
                let t = line.trimmedLeft
                if !content.isEmpty, t.allSatisfy({ $0 == "=" }), t.count >= 1 {
                    let node = BlockNode(.heading(level: 1, inlines: inline.parse(content.joined(separator: "\n"))),
                                         range: range(lines, start, i))
                    return (node, i + 1)
                }
                if !content.isEmpty, t.allSatisfy({ $0 == "-" }), t.count >= 1 {
                    let node = BlockNode(.heading(level: 2, inlines: inline.parse(content.joined(separator: "\n"))),
                                         range: range(lines, start, i))
                    return (node, i + 1)
                }
            }
            // Stop if a new block structure begins mid-paragraph.
            if i > start, startsNewBlock(line) { break }
            content.append(line.text)
            i += 1
        }
        let node = BlockNode(.paragraph(inline.parse(content.joined(separator: "\n"))),
                             range: range(lines, start, max(start, i - 1)))
        return (node, i)
    }

    private func startsNewBlock(_ line: SourceLine) -> Bool {
        let t = line.trimmedLeft
        if t.hasPrefix("#"), t.prefix(7).contains(" ") || t.allSatisfy({ $0 == "#" }) { return true }
        if t.hasPrefix("```") || t.hasPrefix("~~~") { return true }
        if t.hasPrefix(">") { return true }
        if listMarker(line) != nil { return true }
        return false
    }
}
