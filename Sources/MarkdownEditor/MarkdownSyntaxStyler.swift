#if os(iOS) || os(macOS)
import SwiftUI
import SwiftMarkdownEngine

/// Applies live, syntax-aware attributes to Markdown source while keeping the raw
/// characters intact. Uses lightweight regex scanning so it can attach character
/// ranges directly and run cheaply on every edit.
struct MarkdownSyntaxStyler {
    let theme: MarkdownTheme

    private static let patterns: [(regex: NSRegularExpression, kind: Kind)] = build()

    enum Kind { case fencedCode, heading, bold, italic, inlineCode, link, wikiLink, math }

    /// Produces a styled attributed string for `text`.
    func styled(_ text: String) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text)
        let full = NSRange(location: 0, length: (text as NSString).length)

        // Base attributes.
        result.addAttribute(.font, value: EditorFont.body(), range: full)
        result.addAttribute(.foregroundColor, value: PlatformColor.from(theme.textPrimary), range: full)

        for (regex, kind) in Self.patterns {
            regex.enumerateMatches(in: text, range: full) { match, _, _ in
                guard let match else { return }
                apply(kind, to: result, match: match)
            }
        }
        return result
    }

    private func apply(_ kind: Kind, to string: NSMutableAttributedString, match: NSTextCheckingResult) {
        let range = match.range
        switch kind {
        case .fencedCode, .inlineCode:
            string.addAttribute(.font, value: EditorFont.monospaced(), range: range)
            string.addAttribute(.foregroundColor, value: PlatformColor.from(theme.codeText), range: range)
            string.addAttribute(.backgroundColor, value: PlatformColor.from(theme.codeBackground), range: range)
        case .heading:
            let level = headingLevel(string.string, range: range)
            string.addAttribute(.font, value: EditorFont.heading(level: level), range: range)
        case .bold:
            string.addAttribute(.font, value: EditorFont.bold(), range: range)
        case .italic:
            string.addAttribute(.font, value: EditorFont.italic(), range: range)
        case .link, .wikiLink:
            string.addAttribute(.foregroundColor, value: PlatformColor.from(theme.accent), range: range)
        case .math:
            string.addAttribute(.font, value: EditorFont.monospaced(), range: range)
            string.addAttribute(.foregroundColor, value: PlatformColor.from(theme.accent), range: range)
        }
    }

    private func headingLevel(_ text: String, range: NSRange) -> Int {
        let ns = text as NSString
        let line = ns.substring(with: range)
        return min(6, line.prefix { $0 == "#" }.count)
    }

    private static func build() -> [(NSRegularExpression, Kind)] {
        func re(_ pattern: String, _ options: NSRegularExpression.Options = []) -> NSRegularExpression {
            // Patterns are static and known-valid.
            try! NSRegularExpression(pattern: pattern, options: options)
        }
        // Order matters: fenced code and headings first, bold before italic.
        return [
            (re("```[\\s\\S]*?```", []), .fencedCode),
            (re("^#{1,6} .*$", [.anchorsMatchLines]), .heading),
            (re("\\*\\*[^*\\n]+\\*\\*", []), .bold),
            (re("(?<![*])\\*[^*\\n]+\\*(?![*])", []), .italic),
            (re("`[^`\\n]+`", []), .inlineCode),
            (re("\\[\\[[^\\]\\n]+\\]\\]", []), .wikiLink),
            (re("\\[[^\\]\\n]*\\]\\([^)\\n]*\\)", []), .link),
            (re("\\$[^$\\n]+\\$", []), .math),
        ]
    }
}
#endif
