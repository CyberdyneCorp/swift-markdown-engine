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
