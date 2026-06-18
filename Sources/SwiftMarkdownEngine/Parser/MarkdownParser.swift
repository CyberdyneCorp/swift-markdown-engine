import Foundation

/// Parses Markdown source (CommonMark + GFM + extensions) into a `MarkdownDocument`.
///
/// The parser is a value type with no shared state, so it is safe to run off the
/// main actor. Parsing never throws or crashes on arbitrary input; unresolved
/// constructs degrade to literal text.
public struct MarkdownParser: Sendable {
    /// Toggles for optional extensions.
    public var mathEnabled: Bool
    public var wikiLinksEnabled: Bool

    public init(mathEnabled: Bool = true, wikiLinksEnabled: Bool = true) {
        self.mathEnabled = mathEnabled
        self.wikiLinksEnabled = wikiLinksEnabled
    }

    /// Parses `source` into an immutable document model.
    public func parse(_ source: String) -> MarkdownDocument {
        var lines = SourceLines.split(source)

        let frontmatter = extractFrontmatter(&lines)
        let (referenceLinks, footnotes, contentLines) = collectDefinitions(lines)

        let blockParser = BlockParser(referenceLinks: referenceLinks, mathEnabled: mathEnabled, wikiLinksEnabled: wikiLinksEnabled)
        let footnoteBlocks = footnotes.mapValues { blockParser.parse($0) }
        let blocks = blockParser.parse(contentLines)

        return MarkdownDocument(
            blocks: blocks,
            frontmatter: frontmatter,
            footnotes: footnoteBlocks,
            source: source
        )
    }

    // MARK: - Frontmatter

    private func extractFrontmatter(_ lines: inout [SourceLine]) -> Frontmatter? {
        guard let first = lines.first, first.text.trimmingCharacters(in: .whitespaces) == "---" else { return nil }
        var i = 1
        var raw: [String] = []
        while i < lines.count {
            if lines[i].text.trimmingCharacters(in: .whitespaces) == "---" { break }
            raw.append(lines[i].text)
            i += 1
        }
        guard i < lines.count else { return nil } // no closing fence => not frontmatter
        lines = Array(lines[(i + 1)...])
        let rawText = raw.joined(separator: "\n")
        return Frontmatter(raw: rawText, values: parseYAMLScalars(raw))
    }

    private func parseYAMLScalars(_ lines: [String]) -> [String: String] {
        var values: [String: String] = [:]
        for line in lines {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces)
            var value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            if value.hasPrefix("\""), value.hasSuffix("\""), value.count >= 2 { value = String(value.dropFirst().dropLast()) }
            if !key.isEmpty { values[key] = value }
        }
        return values
    }

    // MARK: - Reference link & footnote definitions

    private func collectDefinitions(
        _ lines: [SourceLine]
    ) -> (refs: [String: LinkReference], footnotes: [String: [SourceLine]], content: [SourceLine]) {
        var refs: [String: LinkReference] = [:]
        var footnotes: [String: [SourceLine]] = [:]
        var content: [SourceLine] = []

        var i = 0
        while i < lines.count {
            let line = lines[i]
            if let (label, ref) = parseLinkReferenceDefinition(line.text) {
                refs[label.lowercased()] = ref
                i += 1
                continue
            }
            if let (label, firstText) = parseFootnoteDefinitionStart(line.text) {
                var noteLines = [SourceLine(text: firstText, start: line.start, contentEnd: line.contentEnd)]
                i += 1
                // Indented continuation lines belong to the footnote.
                while i < lines.count, (lines[i].indent >= 4 || lines[i].isBlank), parseFootnoteDefinitionStart(lines[i].text) == nil {
                    if lines[i].isBlank, i + 1 < lines.count, lines[i + 1].indent < 4 { break }
                    noteLines.append(lines[i]); i += 1
                }
                footnotes[label] = noteLines
                continue
            }
            content.append(line)
            i += 1
        }
        return (refs, footnotes, content)
    }

    private func parseLinkReferenceDefinition(_ text: String) -> (label: String, ref: LinkReference)? {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard t.hasPrefix("["), !t.hasPrefix("[^"), let close = t.firstIndex(of: "]") else { return nil }
        let afterClose = t.index(after: close)
        guard afterClose < t.endIndex, t[afterClose] == ":" else { return nil }
        let label = String(t[t.index(after: t.startIndex)..<close])
        guard !label.isEmpty else { return nil }
        var rest = String(t[t.index(after: afterClose)...]).trimmingCharacters(in: .whitespaces)
        guard !rest.isEmpty else { return nil }
        var title: String?
        if let spaceQuote = rest.range(of: " \"") ?? rest.range(of: " '") {
            let dest = String(rest[..<spaceQuote.lowerBound])
            title = String(rest[spaceQuote.lowerBound...]).trimmingCharacters(in: CharacterSet(charactersIn: " \"'"))
            rest = dest
        }
        if rest.hasPrefix("<"), rest.hasSuffix(">") { rest = String(rest.dropFirst().dropLast()) }
        return (label, LinkReference(destination: rest, title: title))
    }

    private func parseFootnoteDefinitionStart(_ text: String) -> (label: String, firstText: String)? {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard t.hasPrefix("[^"), let close = t.firstIndex(of: "]") else { return nil }
        let afterClose = t.index(after: close)
        guard afterClose < t.endIndex, t[afterClose] == ":" else { return nil }
        let label = String(t[t.index(t.startIndex, offsetBy: 2)..<close])
        guard !label.isEmpty else { return nil }
        let firstText = String(t[t.index(after: afterClose)...]).trimmingCharacters(in: .whitespaces)
        return (label, firstText)
    }
}
