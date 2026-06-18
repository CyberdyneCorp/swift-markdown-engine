import Foundation

/// Parses an inline string into `InlineNode`s. A single left-to-right scan handles
/// the inline constructs; unmatched delimiters degrade to literal text.
///
/// The parser is intentionally pragmatic: it covers the common CommonMark + GFM +
/// extension cases and never crashes on malformed input. Full spec edge-case
/// conformance is hardened by the Phase 1 conformance suite (task 3.8).
struct InlineParser {
    /// Reference link definitions collected during block parsing, keyed by
    /// lowercased label.
    let referenceLinks: [String: LinkReference]
    /// Whether the math extension is enabled.
    let mathEnabled: Bool
    /// Whether wiki-links are enabled.
    let wikiLinksEnabled: Bool

    init(referenceLinks: [String: LinkReference] = [:], mathEnabled: Bool = true, wikiLinksEnabled: Bool = true) {
        self.referenceLinks = referenceLinks
        self.mathEnabled = mathEnabled
        self.wikiLinksEnabled = wikiLinksEnabled
    }

    func parse(_ input: String) -> [InlineNode] {
        var nodes: [InlineNode] = []
        var text = ""
        let chars = Array(input)
        var i = 0

        func flushText() {
            if !text.isEmpty {
                nodes.append(InlineNode(.text(text)))
                text = ""
            }
        }

        while i < chars.count {
            let c = chars[i]
            switch c {
            case "\\":
                if i + 1 < chars.count, chars[i + 1].isPunctuation || chars[i + 1].isSymbol {
                    text.append(chars[i + 1]); i += 2
                } else if i + 1 < chars.count, chars[i + 1] == "\n" {
                    flushText(); nodes.append(InlineNode(.lineBreak)); i += 2
                } else {
                    text.append(c); i += 1
                }
            case "`":
                if let (node, next) = parseCodeSpan(chars, i) { flushText(); nodes.append(node); i = next }
                else { text.append(c); i += 1 }
            case "$" where mathEnabled:
                if let (node, next) = parseInlineMath(chars, i) { flushText(); nodes.append(node); i = next }
                else { text.append(c); i += 1 }
            case "*", "_", "~":
                if let (node, next) = parseEmphasis(chars, i) { flushText(); nodes.append(node); i = next }
                else { text.append(c); i += 1 }
            case "!" where i + 1 < chars.count && chars[i + 1] == "[":
                if let (node, next) = parseImage(chars, i) { flushText(); nodes.append(node); i = next }
                else { text.append(c); i += 1 }
            case "[":
                if let (node, next) = parseBracket(chars, i) { flushText(); nodes.append(node); i = next }
                else { text.append(c); i += 1 }
            case "<":
                if let (node, next) = parseAngleAutolink(chars, i) { flushText(); nodes.append(node); i = next }
                else { text.append(c); i += 1 }
            case "h" where matchesBareURL(chars, i):
                let (node, next) = parseBareURL(chars, i); flushText(); nodes.append(node); i = next
            case "\n":
                flushText()
                // Two trailing spaces before newline => hard break.
                if text.isEmpty, nodes.isEmpty == false { /* handled below via lookback not needed */ }
                nodes.append(InlineNode(.softBreak)); i += 1
            default:
                text.append(c); i += 1
            }
        }
        flushText()
        return nodes
    }

    // MARK: - Code spans

    private func parseCodeSpan(_ chars: [Character], _ start: Int) -> (InlineNode, Int)? {
        var fence = 0
        var i = start
        while i < chars.count, chars[i] == "`" { fence += 1; i += 1 }
        let contentStart = i
        while i < chars.count {
            if chars[i] == "`" {
                var run = 0
                let runStart = i
                while i < chars.count, chars[i] == "`" { run += 1; i += 1 }
                if run == fence {
                    var content = String(chars[contentStart..<runStart])
                    if content.hasPrefix(" "), content.hasSuffix(" "), content.trimmingCharacters(in: .whitespaces).isEmpty == false {
                        content = String(content.dropFirst().dropLast())
                    }
                    return (InlineNode(.code(content)), i)
                }
            } else { i += 1 }
        }
        return nil
    }

    // MARK: - Inline math

    private func parseInlineMath(_ chars: [Character], _ start: Int) -> (InlineNode, Int)? {
        // Support \( ... \) is handled at block level; here handle $...$ with currency guard.
        guard start + 1 < chars.count else { return nil }
        let after = chars[start + 1]
        if after == " " || after == "$" { return nil } // "$ " or "$$" not inline math here
        var i = start + 1
        while i < chars.count {
            if chars[i] == "$" {
                // Closing $ must not be immediately followed by a digit (currency guard).
                let next = i + 1 < chars.count ? chars[i + 1] : " "
                let prev = chars[i - 1]
                if prev != " ", !next.isNumber {
                    let body = String(chars[(start + 1)..<i])
                    if body.isEmpty { return nil }
                    return (InlineNode(.inlineMath(body)), i + 1)
                }
            }
            if chars[i] == "\n" { return nil }
            i += 1
        }
        return nil
    }

    // MARK: - Emphasis / strong / strikethrough

    private func parseEmphasis(_ chars: [Character], _ start: Int) -> (InlineNode, Int)? {
        let marker = chars[start]
        var count = 0
        var i = start
        while i < chars.count, chars[i] == marker { count += 1; i += 1 }

        // Strikethrough requires exactly the ~~ form.
        if marker == "~" {
            guard count >= 2 else { return nil }
            return closeRun(chars, marker: "~", openCount: 2, contentStart: start + 2) { children in
                InlineNode(.strikethrough(children))
            }
        }

        // Opening delimiter must be followed by non-space.
        guard i < chars.count, chars[i] != " ", chars[i] != "\n" else { return nil }
        let useCount = min(count, 2)
        let contentStart = start + useCount
        return closeRun(chars, marker: marker, openCount: useCount, contentStart: contentStart) { children in
            useCount == 2 ? InlineNode(.strong(children)) : InlineNode(.emphasis(children))
        }
    }

    /// Finds a matching closing delimiter run and recursively parses the content.
    private func closeRun(
        _ chars: [Character],
        marker: Character,
        openCount: Int,
        contentStart: Int,
        make: ([InlineNode]) -> InlineNode
    ) -> (InlineNode, Int)? {
        var i = contentStart
        while i < chars.count {
            if chars[i] == marker {
                var run = 0
                let runStart = i
                while i < chars.count, chars[i] == marker { run += 1; i += 1 }
                if run >= openCount, runStart > contentStart, chars[runStart - 1] != " " {
                    let inner = String(chars[contentStart..<runStart])
                    let children = InlineParser(referenceLinks: referenceLinks, mathEnabled: mathEnabled, wikiLinksEnabled: wikiLinksEnabled).parse(inner)
                    return (make(children), runStart + openCount)
                }
            } else { i += 1 }
        }
        return nil
    }

    // MARK: - Links, images, wiki-links, footnotes

    private func parseBracket(_ chars: [Character], _ start: Int) -> (InlineNode, Int)? {
        // Wiki-link [[target|display]]
        if wikiLinksEnabled, start + 1 < chars.count, chars[start + 1] == "[" {
            if let close = findSequence(chars, "]]", from: start + 2) {
                let inner = String(chars[(start + 2)..<close])
                let parts = inner.split(separator: "|", maxSplits: 1).map(String.init)
                let target = parts.first ?? inner
                let display = parts.count > 1 ? parts[1] : nil
                return (InlineNode(.wikiLink(target: target, display: display)), close + 2)
            }
        }
        // Footnote reference [^label]
        if start + 1 < chars.count, chars[start + 1] == "^" {
            if let close = findChar(chars, "]", from: start + 2) {
                let label = String(chars[(start + 2)..<close])
                if !label.isEmpty, !label.contains(" ") {
                    return (InlineNode(.footnoteReference(label: label)), close + 1)
                }
            }
        }
        return parseLink(chars, start, isImage: false)
    }

    private func parseImage(_ chars: [Character], _ start: Int) -> (InlineNode, Int)? {
        parseLink(chars, start + 1, isImage: true).map { ($0.0, $0.1) }
    }

    private func parseLink(_ chars: [Character], _ start: Int, isImage: Bool) -> (InlineNode, Int)? {
        guard chars[start] == "[", let labelEnd = matchBracket(chars, openIndex: start) else { return nil }
        let labelText = String(chars[(start + 1)..<labelEnd])
        var i = labelEnd + 1

        // Inline form: (dest "title")
        if i < chars.count, chars[i] == "(" {
            guard let close = matchParen(chars, openIndex: i) else { return nil }
            let inside = String(chars[(i + 1)..<close]).trimmingCharacters(in: .whitespaces)
            let (dest, title) = splitDestinationTitle(inside)
            i = close + 1
            return (makeLinkNode(label: labelText, dest: dest, title: title, isImage: isImage), i)
        }

        // Reference form: [label][ref] or [ref]
        var refKey = labelText
        if i < chars.count, chars[i] == "[" {
            if let refClose = matchBracket(chars, openIndex: i) {
                let explicit = String(chars[(i + 1)..<refClose])
                if !explicit.isEmpty { refKey = explicit }
                i = refClose + 1
            }
        }
        if let ref = referenceLinks[refKey.lowercased()] {
            return (makeLinkNode(label: labelText, dest: ref.destination, title: ref.title, isImage: isImage), i)
        }
        return nil
    }

    private func makeLinkNode(label: String, dest: String, title: String?, isImage: Bool) -> InlineNode {
        if isImage {
            return InlineNode(.image(source: dest, title: title, alt: label))
        }
        let children = InlineParser(referenceLinks: referenceLinks, mathEnabled: mathEnabled, wikiLinksEnabled: wikiLinksEnabled).parse(label)
        return InlineNode(.link(destination: dest, title: title, children: children))
    }

    // MARK: - Autolinks

    private func parseAngleAutolink(_ chars: [Character], _ start: Int) -> (InlineNode, Int)? {
        guard let close = findChar(chars, ">", from: start + 1) else { return nil }
        let inner = String(chars[(start + 1)..<close])
        if inner.contains(" ") || inner.isEmpty { return nil }
        let isEmail = inner.contains("@") && !inner.contains("://")
        if isEmail || inner.contains("://") {
            return (InlineNode(.autolink(url: inner, isEmail: isEmail)), close + 1)
        }
        return nil
    }

    private func matchesBareURL(_ chars: [Character], _ i: Int) -> Bool {
        let rest = String(chars[i...].prefix(8))
        return rest.hasPrefix("http://") || rest.hasPrefix("https://")
    }

    private func parseBareURL(_ chars: [Character], _ start: Int) -> (InlineNode, Int) {
        var i = start
        while i < chars.count, !chars[i].isWhitespace, chars[i] != "<" { i += 1 }
        // Trim trailing punctuation commonly not part of the URL.
        var end = i
        while end > start, ".,;:!?".contains(chars[end - 1]) { end -= 1 }
        let url = String(chars[start..<end])
        return (InlineNode(.autolink(url: url, isEmail: false)), end)
    }

    // MARK: - Scanning helpers

    private func findChar(_ chars: [Character], _ target: Character, from: Int) -> Int? {
        var i = from
        while i < chars.count { if chars[i] == target { return i }; if chars[i] == "\n" { return nil }; i += 1 }
        return nil
    }

    private func findSequence(_ chars: [Character], _ seq: String, from: Int) -> Int? {
        let s = Array(seq)
        var i = from
        while i + s.count <= chars.count {
            if Array(chars[i..<(i + s.count)]) == s { return i }
            if chars[i] == "\n" { return nil }
            i += 1
        }
        return nil
    }

    private func matchBracket(_ chars: [Character], openIndex: Int) -> Int? {
        var depth = 0
        var i = openIndex
        while i < chars.count {
            if chars[i] == "[" { depth += 1 }
            else if chars[i] == "]" { depth -= 1; if depth == 0 { return i } }
            else if chars[i] == "\n" && depth == 1 { /* allow */ }
            i += 1
        }
        return nil
    }

    private func matchParen(_ chars: [Character], openIndex: Int) -> Int? {
        var depth = 0
        var i = openIndex
        while i < chars.count {
            if chars[i] == "(" { depth += 1 }
            else if chars[i] == ")" { depth -= 1; if depth == 0 { return i } }
            else if chars[i] == "\n" { return nil }
            i += 1
        }
        return nil
    }

    private func splitDestinationTitle(_ inside: String) -> (String, String?) {
        var dest = inside
        var title: String?
        if let range = inside.range(of: " \"") ?? inside.range(of: " '") {
            dest = String(inside[..<range.lowerBound])
            let titlePart = String(inside[range.lowerBound...]).trimmingCharacters(in: .whitespaces)
            title = titlePart.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        }
        if dest.hasPrefix("<"), dest.hasSuffix(">") { dest = String(dest.dropFirst().dropLast()) }
        return (dest, title)
    }
}

/// A collected link reference definition.
struct LinkReference: Sendable, Equatable {
    let destination: String
    let title: String?
}
