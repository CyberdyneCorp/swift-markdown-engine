import SwiftUI

/// Renders a fenced code block: distinct surface, whitespace preserved, horizontal
/// scroll for long lines, with optional line numbers and a copy control.
///
/// Syntax highlighting is applied via the injected `SyntaxHighlighter` (Phase 3);
/// without one, code renders as plain monospaced text.
struct CodeBlockView: View {
    let language: String?
    let code: String

    @Environment(\.resolvedMarkdownTheme) private var theme
    @Environment(\.markdownServices) private var services
    @Environment(\.markdownConfiguration) private var config

    private var lines: [String] { code.components(separatedBy: "\n") }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if config.showCodeCopyButton || language != nil {
                header
            }
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: 10) {
                    if config.showCodeLineNumbers { lineNumbers }
                    codeText
                }
                .padding(10)
            }
        }
        .background(theme.codeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var header: some View {
        HStack {
            if let language { Text(language).font(.caption).foregroundStyle(theme.textSecondary) }
            Spacer()
            #if os(iOS) || os(macOS)
            if config.showCodeCopyButton {
                Button {
                    copyToPasteboard(code)
                } label: {
                    Image(systemName: "doc.on.doc").font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.textSecondary)
                .accessibilityLabel("Copy code")
            }
            #endif
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
    }

    private var codeText: some View {
        let text = Text(highlighted)
            .font(theme.codeFont)
            .fixedSize(horizontal: true, vertical: false)
        #if os(watchOS)
        return text
        #else
        return text.textSelection(.enabled)
        #endif
    }

    private var lineNumbers: some View {
        Text(lines.indices.map { String($0 + 1) }.joined(separator: "\n"))
            .font(theme.codeFont)
            .foregroundStyle(theme.textSecondary)
            .multilineTextAlignment(.trailing)
    }

    private var highlighted: AttributedString {
        if let highlighter = services.syntaxHighlighter {
            return highlighter.highlight(code, language: CodeLanguage.canonical(language))
        }
        var a = AttributedString(code)
        a.foregroundColor = theme.codeText
        return a
    }
}
