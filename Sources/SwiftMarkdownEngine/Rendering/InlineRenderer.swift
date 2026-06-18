import SwiftUI

/// Builds a SwiftUI-renderable `AttributedString` from inline nodes. Kept separate
/// from views so it can be unit-tested directly.
///
/// Inline math and inline images are rendered as styled text placeholders here;
/// Phase 3 upgrades inline math to a flow layout with embedded formula views.
struct InlineRenderer {
    let theme: MarkdownTheme
    /// When present, inline math is rendered as a baseline-flowed image instead of
    /// styled source text.
    var latexRenderer: (any LatexRenderer)?

    init(theme: MarkdownTheme, latexRenderer: (any LatexRenderer)? = nil) {
        self.theme = theme
        self.latexRenderer = latexRenderer
    }

    func attributedString(for inlines: [InlineNode]) -> AttributedString {
        var result = AttributedString()
        for node in inlines {
            result.append(render(node, intent: []))
        }
        return result
    }

    /// Builds a SwiftUI `Text` that flows styled runs together with inline math
    /// images (when a `LatexRenderer` is available), interleaving them inline.
    func text(for inlines: [InlineNode]) -> Text {
        var result = Text("")
        var buffer = AttributedString()

        func flush() {
            if !buffer.characters.isEmpty {
                result = result + Text(buffer)
                buffer = AttributedString()
            }
        }

        for node in inlines {
            if case .inlineMath(let mathBody) = node.kind,
               let renderer = latexRenderer,
               let data = renderer.renderToPNG(mathBody, displayMode: false, pointSize: 16,
                                               hexColor: theme.textPrimary.hexString()),
               let image = makeImage(from: data) {
                flush()
                result = result + Text(image)
            } else {
                buffer.append(render(node, intent: []))
            }
        }
        flush()
        return result
    }

    private func render(_ node: InlineNode, intent: InlinePresentationIntent) -> AttributedString {
        switch node.kind {
        case .text(let s):
            return styled(s, intent: intent)
        case .softBreak:
            return styled(" ", intent: intent)
        case .lineBreak:
            return styled("\n", intent: intent)
        case .code(let code):
            var a = styled(code, intent: intent.union(.code))
            a.font = theme.codeFont
            a.backgroundColor = theme.codeBackground
            a.foregroundColor = theme.codeText
            return a
        case .emphasis(let children):
            return concat(children, intent: intent.union(.emphasized))
        case .strong(let children):
            return concat(children, intent: intent.union(.stronglyEmphasized))
        case .strikethrough(let children):
            return concat(children, intent: intent.union(.strikethrough))
        case .link(let destination, _, let children):
            var a = concat(children, intent: intent)
            if let url = URL(string: destination) { a.link = url }
            a.foregroundColor = theme.accent
            return a
        case .image(_, _, let alt):
            return styled(alt, intent: intent)
        case .autolink(let url, let isEmail):
            var a = styled(url, intent: intent)
            a.link = URL(string: isEmail ? "mailto:\(url)" : url)
            a.foregroundColor = theme.accent
            return a
        case .wikiLink(let target, let display):
            var a = styled(display ?? target, intent: intent)
            a.foregroundColor = theme.accent
            return a
        case .footnoteReference(let label):
            var a = styled("[\(label)]", intent: intent)
            a.foregroundColor = theme.accent
            return a
        case .inlineMath(let body):
            var a = styled(body, intent: intent.union(.code))
            a.font = theme.codeFont
            a.foregroundColor = theme.accent
            return a
        case .inlineHTML(let html):
            return styled(html, intent: intent)
        }
    }

    private func concat(_ children: [InlineNode], intent: InlinePresentationIntent) -> AttributedString {
        var result = AttributedString()
        for child in children { result.append(render(child, intent: intent)) }
        return result
    }

    private func styled(_ string: String, intent: InlinePresentationIntent) -> AttributedString {
        var a = AttributedString(string)
        if !intent.isEmpty { a.inlinePresentationIntent = intent }
        return a
    }
}
