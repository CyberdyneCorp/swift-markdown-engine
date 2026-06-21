import XCTest
@testable import SwiftMarkdownEngine

/// Round-trip tests for Markdown serialization: parse → serialize → parse must yield an
/// equal document model (model fidelity, not byte-identical source).
final class SerializationTests: XCTestCase {
    private let parser = MarkdownParser()

    private func roundTrip(_ src: String, file: StaticString = #filePath, line: UInt = #line) {
        let doc1 = parser.parse(src)
        let serialized = doc1.markdown()
        let doc2 = parser.parse(serialized)
        XCTAssertEqual(doc1.blocks, doc2.blocks,
                       "round-trip mismatch; serialized form was:\n\(serialized)",
                       file: file, line: line)
    }

    func testHeadings() {
        roundTrip("# One\n\n## Two\n\n### Three\n\n###### Six\n")
    }

    func testInlineFormatting() {
        roundTrip("A paragraph with **bold**, *italic*, ~~strike~~, `code`, and [a link](https://x.com).\n")
    }

    func testNestedLists() {
        roundTrip("- one\n- two\n  - nested a\n  - nested b\n- three\n")
    }

    func testOrderedList() {
        roundTrip("1. first\n2. second\n3. third\n")
    }

    func testTaskList() {
        roundTrip("- [x] done\n- [ ] todo\n")
    }

    func testTableWithAlignment() {
        roundTrip("| L | C | R |\n| :--- | :---: | ---: |\n| a | b | c |\n| d | e | f |\n")
    }

    func testFencedCode() {
        roundTrip("```swift\nlet x = 1\nprint(x)\n```\n")
    }

    func testMathBlock() {
        roundTrip("$$\n\\int_0^1 x\\,dx\n$$\n")
    }

    func testImageAndBlockQuote() {
        roundTrip("> a quote with **emphasis**\n\n![alt text](https://x.com/a.png)\n")
    }

    func testMermaid() {
        roundTrip("```mermaid\nflowchart LR\n  A --> B\n```\n")
    }

    func testComprehensiveDocument() {
        roundTrip("""
        # Title

        Intro with **bold** and a [link](https://example.com).

        ## List

        - alpha
        - beta
          - nested

        ## Table

        | Name | Qty |
        | :--- | ---: |
        | Apple | 3 |

        ```python
        print("hi")
        ```

        $$
        E = mc^2
        $$
        """)
    }

    func testProgrammaticTaskItemSerializesWithSpace() {
        // A task item built in code (body has no leading space) must still serialize as
        // "- [x] text" — the editor relies on this.
        let para = BlockNode(.paragraph([InlineNode(.text("Buy milk"))]))
        let item = ListItem(blocks: [para], checkbox: .checked)
        let list = BlockNode(.list(MarkdownList(marker: .bullet, isTight: true, items: [item])))
        let md = list.markdown()
        XCTAssertEqual(md, "- [x] Buy milk")
        // And it re-parses back to a checked task item.
        guard case .list(let parsed)? = parser.parse(md).blocks.first?.kind else { return XCTFail("not a list") }
        XCTAssertEqual(parsed.items.first?.checkbox, .checked)
    }

    func testSingleBlockSerialization() {
        // A single table block serializes to only its own Markdown.
        let table = parser.parse("| a | b |\n| --- | --- |\n| 1 | 2 |\n").blocks.first
        guard case .table? = table?.kind else { return XCTFail("expected a table block") }
        let md = table!.markdown()
        XCTAssertTrue(md.hasPrefix("| a | b |"), "table fragment should start with the header row")
        XCTAssertTrue(md.contains("| 1 | 2 |"), "table fragment should contain the body row")
        XCTAssertFalse(md.contains("\n\n"), "a single block fragment should have no blank-line separators")
    }
}
