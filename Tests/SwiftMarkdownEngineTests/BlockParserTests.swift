import XCTest
@testable import SwiftMarkdownEngine

final class BlockParserTests: XCTestCase {
    private let parser = MarkdownParser()

    private func firstBlock(_ source: String) -> BlockKind? { parser.parse(source).blocks.first?.kind }

    func testATXHeadings() {
        guard case .heading(let level, let inlines)? = firstBlock("## Hello\n") else { return XCTFail("not heading") }
        XCTAssertEqual(level, 2)
        XCTAssertEqual(inlines.first?.kind, .text("Hello"))
    }

    func testSetextHeading() {
        guard case .heading(let level, _)? = firstBlock("Title\n===\n") else { return XCTFail("not heading") }
        XCTAssertEqual(level, 1)
    }

    func testThematicBreak() {
        XCTAssertEqual(firstBlock("***\n"), .thematicBreak)
        XCTAssertEqual(firstBlock("---\n"), .thematicBreak)
    }

    func testFencedCodeWithLanguage() {
        guard case .codeBlock(let language, let content)? = firstBlock("```swift\nlet x = 1\n```\n") else {
            return XCTFail("not code block")
        }
        XCTAssertEqual(language, "swift")
        XCTAssertEqual(content, "let x = 1")
    }

    func testMermaidFenceBecomesMermaidNode() {
        guard case .mermaid(let source)? = firstBlock("```mermaid\nflowchart LR\nA-->B\n```\n") else {
            return XCTFail("not mermaid")
        }
        XCTAssertTrue(source.contains("flowchart LR"))
    }

    func testUnterminatedFenceDoesNotCrash() {
        guard case .codeBlock(_, let content)? = firstBlock("```\nno close") else { return XCTFail("not code") }
        XCTAssertEqual(content, "no close")
    }

    func testBlockMathSingleAndMultiLine() {
        guard case .mathBlock(let body)? = firstBlock("$$\\int_0^1 x\\,dx$$\n") else { return XCTFail("not math") }
        XCTAssertEqual(body, "\\int_0^1 x\\,dx")
        guard case .mathBlock(let multi)? = firstBlock("$$\na+b\n$$\n") else { return XCTFail("not math") }
        XCTAssertEqual(multi, "a+b")
    }

    func testBlockMathInterruptsParagraphWithoutBlankLine() {
        // Regression: a `$$…$$` block placed directly under a text line (no blank line)
        // used to be folded into the paragraph, leaving the `$$` delimiters as literal text.
        let blocks = parser.parse("A matrix:\n$$\\begin{bmatrix} a & b \\\\ c & d \\end{bmatrix}$$\n").blocks
        XCTAssertEqual(blocks.count, 2)
        guard case .paragraph? = blocks.first?.kind else { return XCTFail("first block should be the text paragraph") }
        guard case .mathBlock(let body)? = blocks.last?.kind else { return XCTFail("second block should be math, not text") }
        XCTAssertEqual(body, "\\begin{bmatrix} a & b \\\\ c & d \\end{bmatrix}")
        XCTAssertFalse(body.contains("$"), "math body must not retain the $$ delimiters")
    }

    func testBlockQuote() {
        guard case .blockQuote(let blocks)? = firstBlock("> quoted\n") else { return XCTFail("not quote") }
        guard case .paragraph(let inlines)? = blocks.first?.kind else { return XCTFail("no paragraph") }
        XCTAssertEqual(inlines.first?.kind, .text("quoted"))
    }

    func testCallout() {
        guard case .callout(let kind, _, _)? = firstBlock("> [!NOTE]\n> body\n") else { return XCTFail("not callout") }
        XCTAssertEqual(kind, .note)
    }

    func testUnorderedListWithNesting() {
        let md = "- a\n  - b\n- c\n"
        guard case .list(let list)? = firstBlock(md) else { return XCTFail("not list") }
        XCTAssertEqual(list.items.count, 2)
        XCTAssertEqual(list.marker, .bullet)
        let firstItemHasNestedList = list.items.first?.blocks.contains { if case .list = $0.kind { return true } else { return false } } ?? false
        XCTAssertTrue(firstItemHasNestedList)
    }

    func testOrderedListStart() {
        guard case .list(let list)? = firstBlock("3. first\n4. second\n") else { return XCTFail("not list") }
        XCTAssertEqual(list.marker, .ordered(start: 3))
    }

    func testTaskListItem() {
        guard case .list(let list)? = firstBlock("- [x] done\n- [ ] todo\n") else { return XCTFail("not list") }
        XCTAssertEqual(list.items.first?.checkbox, .checked)
        XCTAssertEqual(list.items.last?.checkbox, .unchecked)
    }

    func testGFMTableWithAlignment() {
        let md = "| L | C | R |\n|:--|:-:|--:|\n| a | b | c |\n"
        guard case .table(let table)? = firstBlock(md) else { return XCTFail("not table") }
        XCTAssertEqual(table.alignments, [.left, .center, .right])
        XCTAssertEqual(table.header.count, 3)
        XCTAssertEqual(table.rows.count, 1)
    }

    func testFrontmatterExtraction() {
        let doc = parser.parse("---\ntitle: Hello\ndraft: true\n---\n# Body\n")
        XCTAssertEqual(doc.frontmatter?.values["title"], "Hello")
        XCTAssertEqual(doc.frontmatter?.values["draft"], "true")
        guard case .heading? = doc.blocks.first?.kind else { return XCTFail("body should start with heading") }
    }

    func testFootnoteDefinitionCollected() {
        let doc = parser.parse("text[^1]\n\n[^1]: the note\n")
        XCTAssertNotNil(doc.footnotes["1"])
    }

    func testBlockNodesCarrySourceRanges() {
        let doc = parser.parse("# Title\n")
        XCTAssertNotNil(doc.blocks.first?.range)
        XCTAssertEqual(doc.blocks.first?.range?.lowerBound, 0)
    }
}
