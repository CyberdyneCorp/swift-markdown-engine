import Foundation

/// The result of an edit command: the new full text and the selection to apply.
public struct EditResult: Equatable {
    public let text: String
    public let selection: NSRange
    public init(text: String, selection: NSRange) {
        self.text = text
        self.selection = selection
    }
}

/// Pure, UI-free Markdown editing commands operating on text + a UTF-16 selection
/// range (matching `UITextView`/`NSTextView` selected ranges). Kept separate from
/// the views so they can be unit-tested directly.
public enum MarkdownEditCommands {
    // MARK: - Inline wrapping (bold, italic, code, strikethrough)

    /// Wraps the selection in `marker`, or unwraps it if already wrapped (toggle).
    public static func toggleInlineWrap(_ text: String, range: NSRange, marker: String) -> EditResult {
        let ns = text as NSString
        guard range.location != NSNotFound, NSMaxRange(range) <= ns.length else {
            return EditResult(text: text, selection: range)
        }
        let markerLen = (marker as NSString).length
        let selected = ns.substring(with: range)

        // Case 1: markers are inside the selection.
        if selected.hasPrefix(marker), selected.hasSuffix(marker), selected.count >= marker.count * 2 {
            let inner = String(selected.dropFirst(marker.count).dropLast(marker.count))
            let newText = ns.replacingCharacters(in: range, with: inner)
            return EditResult(text: newText, selection: NSRange(location: range.location, length: (inner as NSString).length))
        }

        // Case 2: markers immediately surround the selection.
        if range.location >= markerLen, NSMaxRange(range) + markerLen <= ns.length {
            let before = ns.substring(with: NSRange(location: range.location - markerLen, length: markerLen))
            let after = ns.substring(with: NSRange(location: NSMaxRange(range), length: markerLen))
            if before == marker, after == marker {
                let full = NSRange(location: range.location - markerLen, length: range.length + markerLen * 2)
                let newText = ns.replacingCharacters(in: full, with: selected)
                return EditResult(text: newText, selection: NSRange(location: range.location - markerLen, length: range.length))
            }
        }

        // Case 3: wrap.
        let wrapped = marker + selected + marker
        let newText = ns.replacingCharacters(in: range, with: wrapped)
        return EditResult(text: newText, selection: NSRange(location: range.location + markerLen, length: range.length))
    }

    // MARK: - Headings

    /// Sets the heading level (1–6) on the line(s) covering the selection, replacing
    /// any existing heading prefix. Level 0 removes the heading.
    public static func setHeading(_ text: String, range: NSRange, level: Int) -> EditResult {
        transformLines(text, range: range) { line in
            var stripped = Substring(line)
            while stripped.first == "#" { stripped = stripped.dropFirst() }
            if stripped.first == " " { stripped = stripped.dropFirst() }
            let prefix = level <= 0 ? "" : String(repeating: "#", count: min(level, 6)) + " "
            return prefix + stripped
        }
    }

    // MARK: - Line prefixes (lists, quotes, tasks)

    /// Toggles a line prefix (e.g. `- `, `> `, `- [ ] `) on each line in range.
    public static func toggleLinePrefix(_ text: String, range: NSRange, prefix: String) -> EditResult {
        let lines = currentLines(text, range: range)
        let allHavePrefix = lines.allSatisfy { $0.trimmingLeadingWhitespace().hasPrefix(prefix) }
        return transformLines(text, range: range) { line in
            if allHavePrefix {
                let leading = line.prefix { $0 == " " || $0 == "\t" }
                let rest = String(line.dropFirst(leading.count))
                return String(leading) + String(rest.dropFirst(prefix.count))
            }
            return prefix + line
        }
    }

    /// Toggles a GFM task checkbox on the line at `location`.
    public static func toggleCheckbox(_ text: String, location: Int) -> EditResult {
        let ns = text as NSString
        let lineRange = ns.lineRange(for: NSRange(location: min(location, ns.length), length: 0))
        var line = ns.substring(with: lineRange)
        let newline = line.hasSuffix("\n") ? "\n" : ""
        if newline == "\n" { line.removeLast() }

        let leading = line.prefix { $0 == " " || $0 == "\t" }
        var body = String(line.dropFirst(leading.count))
        if body.hasPrefix("- [ ] ") { body = "- [x] " + body.dropFirst(6) }
        else if body.hasPrefix("- [x] ") || body.hasPrefix("- [X] ") { body = "- [ ] " + body.dropFirst(6) }
        else { return EditResult(text: text, selection: NSRange(location: location, length: 0)) }

        let newText = ns.replacingCharacters(in: lineRange, with: leading + body + newline)
        return EditResult(text: newText, selection: NSRange(location: location, length: 0))
    }

    // MARK: - Indentation

    public static func indent(_ text: String, range: NSRange) -> EditResult {
        transformLines(text, range: range) { "  " + $0 }
    }

    public static func outdent(_ text: String, range: NSRange) -> EditResult {
        transformLines(text, range: range) { line in
            if line.hasPrefix("  ") { return String(line.dropFirst(2)) }
            if line.hasPrefix("\t") || line.hasPrefix(" ") { return String(line.drop { $0 == " " || $0 == "\t" }) }
            return line
        }
    }

    // MARK: - Links

    public static func insertLink(_ text: String, range: NSRange, url: String = "url") -> EditResult {
        let ns = text as NSString
        let selected = ns.substring(with: range)
        let label = selected.isEmpty ? "text" : selected
        let snippet = "[\(label)](\(url))"
        let newText = ns.replacingCharacters(in: range, with: snippet)
        // Select the URL placeholder for quick replacement.
        let urlLocation = range.location + (("[\(label)](" as NSString).length)
        return EditResult(text: newText, selection: NSRange(location: urlLocation, length: (url as NSString).length))
    }

    // MARK: - Smart list continuation (Return key)

    public enum ListContinuation: Equatable {
        case none
        case insert(String)          // text to insert after the newline
        case removeMarker(NSRange)   // empty item: remove the marker instead
    }

    /// Determines what should happen when Return is pressed on the line at `location`.
    public static func listContinuation(_ text: String, location: Int) -> ListContinuation {
        let ns = text as NSString
        let lineRange = ns.lineRange(for: NSRange(location: min(location, ns.length), length: 0))
        var line = ns.substring(with: lineRange)
        if line.hasSuffix("\n") { line.removeLast() }

        let leading = String(line.prefix { $0 == " " || $0 == "\t" })
        let body = line.dropFirst(leading.count)

        // Task item.
        if body.hasPrefix("- [ ] ") || body.hasPrefix("- [x] ") || body.hasPrefix("- [X] ") {
            let content = body.dropFirst(6)
            if content.isEmpty { return .removeMarker(lineRange) }
            return .insert("\n" + leading + "- [ ] ")
        }
        // Bullet.
        if let marker = body.first, "-*+".contains(marker), body.dropFirst().first == " " {
            let content = body.dropFirst(2)
            if content.isEmpty { return .removeMarker(lineRange) }
            return .insert("\n" + leading + "\(marker) ")
        }
        // Ordered.
        let digits = body.prefix { $0.isNumber }
        if !digits.isEmpty, body.dropFirst(digits.count).first == ".", body.dropFirst(digits.count + 1).first == " " {
            let content = body.dropFirst(digits.count + 2)
            if content.isEmpty { return .removeMarker(lineRange) }
            let next = (Int(digits) ?? 1) + 1
            return .insert("\n" + leading + "\(next). ")
        }
        return .none
    }

    // MARK: - Helpers

    private static func currentLines(_ text: String, range: NSRange) -> [String] {
        let ns = text as NSString
        let lineRange = ns.lineRange(for: range)
        return ns.substring(with: lineRange).components(separatedBy: "\n")
    }

    private static func transformLines(_ text: String, range: NSRange, _ transform: (String) -> String) -> EditResult {
        let ns = text as NSString
        let lineRange = ns.lineRange(for: range)
        var block = ns.substring(with: lineRange)
        let trailingNewline = block.hasSuffix("\n")
        if trailingNewline { block.removeLast() }
        let transformed = block.components(separatedBy: "\n").map(transform).joined(separator: "\n") + (trailingNewline ? "\n" : "")
        let newText = ns.replacingCharacters(in: lineRange, with: transformed)
        let newLength = (transformed as NSString).length
        return EditResult(text: newText, selection: NSRange(location: lineRange.location, length: max(0, newLength - (trailingNewline ? 1 : 0))))
    }
}

private extension String {
    func trimmingLeadingWhitespace() -> String {
        String(drop { $0 == " " || $0 == "\t" })
    }
}
