import XCTest
@testable import SwiftMarkdownEngine

final class InlineParserTests: XCTestCase {
    private func inlines(_ source: String) -> [InlineNode] {
        // Wrap as a paragraph and pull its inlines.
        guard case .paragraph(let nodes)? = MarkdownParser().parse(source).blocks.first?.kind else { return [] }
        return nodes
    }

    private func kinds(_ source: String) -> [InlineKind] { inlines(source).map(\.kind) }

    func testEmphasisAndStrong() {
        XCTAssertTrue(kinds("*italic*").contains { if case .emphasis = $0 { return true } else { return false } })
        XCTAssertTrue(kinds("**bold**").contains { if case .strong = $0 { return true } else { return false } })
    }

    func testStrikethrough() {
        XCTAssertTrue(kinds("~~gone~~").contains { if case .strikethrough = $0 { return true } else { return false } })
    }

    func testInlineCode() {
        XCTAssertEqual(kinds("`code`").first, .code("code"))
    }

    func testBackslashEscape() {
        // \* should not start emphasis.
        let ks = kinds("\\*not emphasis\\*")
        XCTAssertFalse(ks.contains { if case .emphasis = $0 { return true } else { return false } })
        if case .text(let t)? = ks.first { XCTAssertTrue(t.contains("*not emphasis*")) }
    }

    func testInlineLink() {
        guard let link = inlines("[text](https://example.com)").first(where: { if case .link = $0.kind { return true } else { return false } }) else {
            return XCTFail("no link")
        }
        if case .link(let dest, _, _) = link.kind { XCTAssertEqual(dest, "https://example.com") }
    }

    func testReferenceLink() {
        let ks = kinds("[text][ref]\n\n[ref]: https://example.com\n")
        guard let link = ks.first(where: { if case .link = $0 { return true } else { return false } }) else {
            return XCTFail("no reference link resolved")
        }
        if case .link(let dest, _, _) = link { XCTAssertEqual(dest, "https://example.com") }
    }

    func testImage() {
        guard let img = inlines("![alt](a.png)").first(where: { if case .image = $0.kind { return true } else { return false } }) else {
            return XCTFail("no image")
        }
        if case .image(let src, _, let alt) = img.kind { XCTAssertEqual(src, "a.png"); XCTAssertEqual(alt, "alt") }
    }

    func testLinkedImageBalancesNestedBrackets() {
        // `[![alt](thumb)](url)` must parse to a link wrapping a single image — the basis
        // for video thumbnails. Relies on matchBracket balancing the nested [ ].
        guard case .link(let dest, _, let children)? = inlines("[![Watch](thumb.png)](https://youtu.be/x)").first?.kind else {
            return XCTFail("expected a link node")
        }
        XCTAssertEqual(dest, "https://youtu.be/x")
        XCTAssertEqual(children.count, 1)
        guard case .image(let src, _, let alt)? = children.first?.kind else { return XCTFail("link should wrap an image") }
        XCTAssertEqual(src, "thumb.png")
        XCTAssertEqual(alt, "Watch")
    }

    func testAutolinkAngleAndBare() {
        XCTAssertTrue(kinds("<https://example.com>").contains { if case .autolink = $0 { return true } else { return false } })
        XCTAssertTrue(kinds("see https://example.com here").contains { if case .autolink = $0 { return true } else { return false } })
    }

    func testWikiLink() {
        guard let wiki = inlines("[[Page Name|alias]]").first(where: { if case .wikiLink = $0.kind { return true } else { return false } }) else {
            return XCTFail("no wiki link")
        }
        if case .wikiLink(let target, let display) = wiki.kind {
            XCTAssertEqual(target, "Page Name")
            XCTAssertEqual(display, "alias")
        }
    }

    func testFootnoteReference() {
        XCTAssertTrue(kinds("text[^1]").contains { if case .footnoteReference = $0 { return true } else { return false } })
    }

    func testInlineMath() {
        XCTAssertTrue(kinds("value $E=mc^2$ here").contains { if case .inlineMath = $0 { return true } else { return false } })
    }

    func testCurrencyIsNotMath() {
        XCTAssertFalse(kinds("it costs $5 and $7").contains { if case .inlineMath = $0 { return true } else { return false } })
    }
}
