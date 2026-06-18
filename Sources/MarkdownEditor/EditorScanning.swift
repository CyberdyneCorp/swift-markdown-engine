import Foundation

/// Pure, UI-free scanning helpers for editor behaviors (spell-check suppression and
/// wiki-link completion). Kept separate from the views so they can be unit-tested.
public enum EditorScanning {
    private static let suppressionPatterns: [NSRegularExpression] = {
        ["```[\\s\\S]*?```", "`[^`\\n]+`", "\\$[^$\\n]+\\$", "\\[\\[[^\\]\\n]*\\]\\]"]
            .compactMap { try? NSRegularExpression(pattern: $0) }
    }()

    /// Ranges where spelling/grammar checking should be suppressed: fenced code,
    /// inline code, math spans, and wiki-links.
    public static func suppressionRanges(in text: String) -> [NSRange] {
        let full = NSRange(location: 0, length: (text as NSString).length)
        var ranges: [NSRange] = []
        for regex in suppressionPatterns {
            regex.enumerateMatches(in: text, range: full) { match, _, _ in
                if let match { ranges.append(match.range) }
            }
        }
        return ranges
    }

    /// Whether `location` falls inside any suppression range.
    public static func isInSuppressedRange(_ text: String, location: Int) -> Bool {
        suppressionRanges(in: text).contains { NSLocationInRange(location, $0) || location == NSMaxRange($0) }
    }

    /// The active wiki-link query if the caret sits inside an unclosed `[[…`.
    /// Returns the range covering the text after `[[` up to the caret, plus the
    /// query string. Returns `nil` when not in a wiki-link context.
    public static func activeWikiQuery(_ text: String, caret: Int) -> (range: NSRange, query: String)? {
        let ns = text as NSString
        guard caret >= 2, caret <= ns.length else { return nil }
        let prefix = ns.substring(to: caret)
        guard let openRange = prefix.range(of: "[[", options: .backwards) else { return nil }
        let afterOpen = prefix[openRange.upperBound...]
        // A closing "]]" between the opener and the caret means we're not inside it.
        if afterOpen.contains("]") { return nil }
        let queryStart = (prefix as NSString).length - (String(afterOpen) as NSString).length
        return (NSRange(location: queryStart, length: caret - queryStart), String(afterOpen))
    }
}
