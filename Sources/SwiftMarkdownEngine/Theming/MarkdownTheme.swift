import SwiftUI

/// Semantic styling tokens for rendering and editing Markdown. Built-in `.light`
/// and `.dark` variants are provided; supply a custom value via `.markdownTheme(_:)`.
public struct MarkdownTheme: Sendable, Equatable {
    // Colors
    public var background: Color
    public var surface: Color
    public var textPrimary: Color
    public var textSecondary: Color
    public var accent: Color
    public var border: Color
    public var codeBackground: Color
    public var codeText: Color
    public var blockQuoteBar: Color

    // Typography
    public var bodyFont: Font
    public var codeFont: Font
    /// Returns the font for a heading of the given level (1–6).
    public var headingFont: @Sendable (Int) -> Font

    // Layout
    public var paragraphSpacing: CGFloat
    public var listIndent: CGFloat
    /// Maximum readable column width; content wider than this (tables, code) breaks out.
    public var readingWidth: CGFloat?

    public init(
        background: Color,
        surface: Color,
        textPrimary: Color,
        textSecondary: Color,
        accent: Color,
        border: Color,
        codeBackground: Color,
        codeText: Color,
        blockQuoteBar: Color,
        bodyFont: Font = .body,
        codeFont: Font = .system(.callout, design: .monospaced),
        headingFont: @escaping @Sendable (Int) -> Font = MarkdownTheme.defaultHeadingFont,
        paragraphSpacing: CGFloat = 12,
        listIndent: CGFloat = 20,
        readingWidth: CGFloat? = nil
    ) {
        self.background = background
        self.surface = surface
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.accent = accent
        self.border = border
        self.codeBackground = codeBackground
        self.codeText = codeText
        self.blockQuoteBar = blockQuoteBar
        self.bodyFont = bodyFont
        self.codeFont = codeFont
        self.headingFont = headingFont
        self.paragraphSpacing = paragraphSpacing
        self.listIndent = listIndent
        self.readingWidth = readingWidth
    }

    /// Default heading fonts map to system text styles so Dynamic Type scales them.
    public static let defaultHeadingFont: @Sendable (Int) -> Font = { level in
        switch level {
        case 1: return .system(.largeTitle, design: .default).weight(.bold)
        case 2: return .system(.title, design: .default).weight(.bold)
        case 3: return .system(.title2, design: .default).weight(.semibold)
        case 4: return .system(.title3, design: .default).weight(.semibold)
        case 5: return .system(.headline, design: .default)
        default: return .system(.subheadline, design: .default).weight(.semibold)
        }
    }

    public static func == (lhs: MarkdownTheme, rhs: MarkdownTheme) -> Bool {
        lhs.background == rhs.background && lhs.surface == rhs.surface
            && lhs.textPrimary == rhs.textPrimary && lhs.textSecondary == rhs.textSecondary
            && lhs.accent == rhs.accent && lhs.border == rhs.border
            && lhs.codeBackground == rhs.codeBackground && lhs.codeText == rhs.codeText
            && lhs.blockQuoteBar == rhs.blockQuoteBar
            && lhs.paragraphSpacing == rhs.paragraphSpacing && lhs.listIndent == rhs.listIndent
            && lhs.readingWidth == rhs.readingWidth
    }
}

public extension MarkdownTheme {
    /// Light appearance.
    static let light = MarkdownTheme(
        background: Color(.sRGB, red: 1, green: 1, blue: 1),
        surface: Color(.sRGB, red: 0.96, green: 0.97, blue: 0.98),
        textPrimary: Color(.sRGB, red: 0.04, green: 0.07, blue: 0.13),
        textSecondary: Color(.sRGB, red: 0.35, green: 0.40, blue: 0.47),
        accent: Color(.sRGB, red: 0.13, green: 0.45, blue: 0.95),
        border: Color(.sRGB, red: 0.85, green: 0.87, blue: 0.90),
        codeBackground: Color(.sRGB, red: 0.95, green: 0.96, blue: 0.97),
        codeText: Color(.sRGB, red: 0.11, green: 0.12, blue: 0.15),
        blockQuoteBar: Color(.sRGB, red: 0.80, green: 0.83, blue: 0.87)
    )

    /// Dark appearance.
    static let dark = MarkdownTheme(
        background: Color(.sRGB, red: 0.07, green: 0.08, blue: 0.10),
        surface: Color(.sRGB, red: 0.12, green: 0.13, blue: 0.16),
        textPrimary: Color(.sRGB, red: 0.95, green: 0.96, blue: 1.0),
        textSecondary: Color(.sRGB, red: 0.66, green: 0.70, blue: 0.77),
        accent: Color(.sRGB, red: 0.40, green: 0.68, blue: 1.0),
        border: Color(.sRGB, red: 0.24, green: 0.26, blue: 0.30),
        codeBackground: Color(.sRGB, red: 0.14, green: 0.15, blue: 0.18),
        codeText: Color(.sRGB, red: 0.90, green: 0.92, blue: 0.96),
        blockQuoteBar: Color(.sRGB, red: 0.32, green: 0.35, blue: 0.40)
    )
}
