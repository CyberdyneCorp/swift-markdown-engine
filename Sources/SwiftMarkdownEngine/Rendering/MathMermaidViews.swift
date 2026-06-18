import SwiftUI

/// Renders block math via the injected `LatexRenderer` (Phase 3). Without one, or
/// when the LaTeX cannot be parsed, it falls back to the raw source as code so the
/// content is never lost.
struct MathBlockView: View {
    let body_: String

    @Environment(\.resolvedMarkdownTheme) private var theme
    @Environment(\.markdownServices) private var services

    init(_ body: String) { self.body_ = body }

    var body: some View {
        // Phase 3 wires the LatexRenderer to produce an image; for now show source.
        Text(body_)
            .font(theme.codeFont)
            .foregroundStyle(theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .accessibilityLabel("math: \(body_)")
    }
}

