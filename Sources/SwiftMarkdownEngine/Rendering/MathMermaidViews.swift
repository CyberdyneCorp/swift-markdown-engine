import SwiftUI

/// Renders block math via the injected `LatexRenderer`. Without one, or when the
/// LaTeX cannot be parsed, it falls back to the raw source styled as code so the
/// content is never lost.
struct MathBlockView: View {
    let body_: String

    @Environment(\.resolvedMarkdownTheme) private var theme
    @Environment(\.markdownServices) private var services
    @Environment(\.displayScale) private var displayScale

    init(_ body: String) { self.body_ = body }

    var body: some View {
        Group {
            if let image = renderedImage {
                // Natural size (not stretched to the column width) keeps display math
                // close to the surrounding text size; horizontal scroll handles a wide
                // formula on a narrow screen instead of blowing it up to fill the column.
                ScrollView(.horizontal, showsIndicators: false) {
                    image.padding(.horizontal, 2)
                }
            } else {
                // Fallback: raw LaTeX source.
                Text(body_)
                    .font(theme.codeFont)
                    .foregroundStyle(theme.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 6)
        .accessibilityLabel("math: \(body_)")
    }

    private var renderedImage: Image? {
        guard let renderer = services.latexRenderer,
              let data = renderer.renderToPNG(body_, displayMode: true, pointSize: 22,
                                              hexColor: theme.textPrimary.hexString())
        else { return nil }
        return makeImage(from: data, scale: displayScale)
    }
}

