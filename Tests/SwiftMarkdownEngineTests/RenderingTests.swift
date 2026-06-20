import XCTest
import SwiftUI
@testable import SwiftMarkdownEngine

final class RenderingTests: XCTestCase {
    private let renderer = InlineRenderer(theme: .light)

    private func inlines(_ source: String) -> [InlineNode] {
        guard case .paragraph(let nodes)? = MarkdownParser().parse(source).blocks.first?.kind else { return [] }
        return nodes
    }

    func testStrongProducesStrongIntent() {
        let a = renderer.attributedString(for: inlines("**bold**"))
        let hasStrong = a.runs.contains { ($0.inlinePresentationIntent ?? []).contains(.stronglyEmphasized) }
        XCTAssertTrue(hasStrong)
    }

    func testEmphasisProducesEmphasisIntent() {
        let a = renderer.attributedString(for: inlines("*it*"))
        let hasEmphasis = a.runs.contains { ($0.inlinePresentationIntent ?? []).contains(.emphasized) }
        XCTAssertTrue(hasEmphasis)
    }

    func testLinkCarriesURL() {
        let a = renderer.attributedString(for: inlines("[t](https://example.com)"))
        let hasLink = a.runs.contains { $0.link == URL(string: "https://example.com") }
        XCTAssertTrue(hasLink)
    }

    func testInlineCodeUsesCodeBackground() {
        let a = renderer.attributedString(for: inlines("`x`"))
        let hasBackground = a.runs.contains { $0.backgroundColor != nil }
        XCTAssertTrue(hasBackground)
    }

    func testCodeLanguageAliasResolution() {
        XCTAssertEqual(CodeLanguage.canonical("py"), "python")
        XCTAssertEqual(CodeLanguage.canonical("C++"), "cpp")
        XCTAssertEqual(CodeLanguage.canonical("swift"), "swift")
        XCTAssertNil(CodeLanguage.canonical(""))
        XCTAssertNil(CodeLanguage.canonical(nil))
    }

    func testConfigurationDisablesMathExtension() {
        var config = MarkdownConfiguration(enabledExtensions: [.mermaid])
        let doc = config.parser.parse("value $E=mc^2$ here")
        let kinds: [InlineKind]
        if case .paragraph(let nodes)? = doc.blocks.first?.kind { kinds = nodes.map(\.kind) } else { kinds = [] }
        XCTAssertFalse(kinds.contains { if case .inlineMath = $0 { return true } else { return false } })
        config.interactiveCheckboxes = true
        XCTAssertTrue(config.interactiveCheckboxes)
    }

    func testThemeLightAndDarkDiffer() {
        XCTAssertNotEqual(MarkdownTheme.light, MarkdownTheme.dark)
    }

    // MARK: - Heading sizing regression (headings rendered at body size)

    private func headingInlines(_ source: String) -> [InlineNode] {
        guard case .heading(_, let nodes)? = MarkdownParser().parse(source).blocks.first?.kind else { return [] }
        return nodes
    }

    func testHeadingFontsAreDistinctPerLevelAndFromBody() {
        let theme = MarkdownTheme.light
        for level in 1...6 {
            XCTAssertNotEqual(theme.headingFont(level), theme.bodyFont,
                              "Heading level \(level) must not equal the body font")
        }
        XCTAssertNotEqual(theme.headingFont(1), theme.headingFont(2))
        XCTAssertNotEqual(theme.headingFont(2), theme.headingFont(3))
    }

    func testHeadingRunsCarryHeadingFontNotBody() {
        // Regression: headings used to render at body size because the body font was
        // baked into the Text and the heading font (applied to an outer wrapper) lost.
        let theme = MarkdownTheme.light
        let renderer = InlineRenderer(theme: theme)
        let h1 = renderer.attributedString(for: headingInlines("# **Title**"),
                                           baseFont: theme.headingFont(1))
        XCTAssertTrue(h1.runs.allSatisfy { $0.font == theme.headingFont(1) },
                      "Every heading run should carry the heading font")
        XCTAssertFalse(h1.runs.contains { $0.font == theme.bodyFont },
                       "No heading run should fall back to the body font")
    }

    // MARK: - Video URL classification

    func testVideoClassifyDirectFiles() {
        XCTAssertEqual(VideoSource.classify("https://cdn.example.com/clip.mp4"), .directFile)
        XCTAssertEqual(VideoSource.classify("https://x.com/a.MOV"), .directFile)            // case-insensitive
        XCTAssertEqual(VideoSource.classify("https://x.com/stream.m3u8?token=abc"), .directFile) // ignores query
        XCTAssertEqual(VideoSource.classify("https://x.com/movie.m4v"), .directFile)
    }

    func testVideoClassifyProviders() {
        XCTAssertEqual(VideoSource.classify("https://www.youtube.com/watch?v=abc"), .provider)
        XCTAssertEqual(VideoSource.classify("https://youtu.be/abc"), .provider)
        XCTAssertEqual(VideoSource.classify("https://m.youtube.com/watch?v=abc"), .provider) // strips m.
        XCTAssertEqual(VideoSource.classify("https://vimeo.com/12345"), .provider)
    }

    func testVideoClassifyNonVideo() {
        XCTAssertEqual(VideoSource.classify("https://example.com/photo.png"), .notVideo)
        XCTAssertEqual(VideoSource.classify("https://example.com/article"), .notVideo)
        XCTAssertEqual(VideoSource.classify("not a url at all"), .notVideo)
    }

    func testBaseFontLeavesInlineCodeFontIntact() {
        // The base font must not clobber runs that set their own font (inline code).
        let theme = MarkdownTheme.light
        let a = InlineRenderer(theme: theme).attributedString(for: inlines("plain `code`"),
                                                              baseFont: theme.headingFont(2))
        XCTAssertTrue(a.runs.contains { $0.font == theme.codeFont }, "inline code keeps its font")
        XCTAssertTrue(a.runs.contains { $0.font == theme.headingFont(2) }, "plain text gets the base font")
    }

    func testViewsInitialize() {
        // Smoke test: views construct without crashing.
        _ = MarkdownView("# Hi\n\nbody")
        _ = MarkdownView(document: MarkdownParser().parse("text"))
        _ = MarkdownTableView(table: MarkdownTable(alignments: [.left], header: [[InlineNode(.text("h"))]], rows: []))
    }
}

private struct StubLatexRenderer: LatexRenderer {
    // A minimal 1x1 transparent PNG so the inline-math image branch is exercised.
    func renderToPNG(_ latex: String, displayMode: Bool, pointSize: Double, hexColor: String) -> Data? {
        Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M8AAAMBAQDJ/pLvAAAAAElFTkSuQmCC")
    }
}

extension RenderingTests {
    func testInlineRendererFlowTextBuilds() {
        // With a renderer, inline math flows as an image; without, it stays text.
        let withMath = InlineRenderer(theme: .light, latexRenderer: StubLatexRenderer())
        _ = withMath.text(for: inlines("value $E=mc^2$ end"))
        let plain = InlineRenderer(theme: .light)
        _ = plain.text(for: inlines("just **bold** text"))
    }
}
