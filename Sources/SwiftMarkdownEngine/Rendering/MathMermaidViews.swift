import SwiftUI

/// Renders block math via the injected `LatexRenderer`. Without one, or when the
/// LaTeX cannot be parsed, it falls back to the raw source styled as code so the
/// content is never lost.
struct MathBlockView: View {
    let body_: String

    @Environment(\.resolvedMarkdownTheme) private var theme
    @Environment(\.markdownServices) private var services

    init(_ body: String) { self.body_ = body }

    var body: some View {
        if let image = renderedImage {
            image
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .accessibilityLabel("math: \(body_)")
        } else {
            // Fallback: raw LaTeX source.
            Text(body_)
                .font(theme.codeFont)
                .foregroundStyle(theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .accessibilityLabel("math: \(body_)")
        }
    }

    private var renderedImage: Image? {
        guard let renderer = services.latexRenderer,
              let data = renderer.renderToPNG(body_, displayMode: true, pointSize: 22,
                                              hexColor: theme.textPrimary.hexString())
        else { return nil }
        return makeImage(from: data)
    }
}

